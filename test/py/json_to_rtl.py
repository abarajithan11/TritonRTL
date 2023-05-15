import qkeras
import json
import tensorflow as tf
import numpy as np


def get_act_txt(model, act_i, name):
  model_a = qkeras.Model(inputs=model.input, outputs=model.layers[act_i].output)
  out_a = model_a(x)
  d1 = model.layers[act_i].get_config()['activation'].get_config()

  if 'keep_negative' in d1:
    frac1 = d1['bits']-d1['integer']-d1['keep_negative']
  else:
    frac1 = d1['bits'] - d1['integer'] - (d1['negative_slope'] !=0)
  out_ai = out_a.numpy()* 2 ** frac1
  assert np.all(out_ai==out_ai.astype(int))
  out_ai = out_ai.astype(int)
  np.savetxt(f'../vectors/{name}.txt', out_ai.flatten(), fmt='%d')


def layer_rtl(model, i):
    layer = model.layers[i]
    if isinstance(layer, qkeras.qconvolutional.QConv2D):
        return f'''
  // Conv {i}

  logic [CONV{i}_XD-1:0] [CONV{i}_XB-1:0] conv{i}_x;
  logic [CONV{i}_KD-1:0] [CONV{i}_KB-1:0] conv{i}_k;
  logic [CONV{i}_BD-1:0] [CONV{i}_KB-1:0] conv{i}_b;
  logic [CONV{i}_YD-1:0] [CONV{i}_YB-1:0] conv{i}_y;

  qconv{i}d #(
    .XN(1), .XH(CONV{i}_XH), .XW(CONV{i}_XW), .XC(CONV{i}_XC), .KH(CONV{i}_KH), .KW(CONV{i}_KW), .SH(CONV{i}_SH), .SW(CONV{i}_SW), .YC(CONV{i}_YC), .XB(CONV{i}_XB), .KB(CONV{i}_KB)
    ) CONV{i} (
    .x(conv{i}_x),
    .k(conv{i}_k),
    .b(conv{i}_b),
    .y(conv{i}_y)
  );
        '''

    if isinstance(layer, qkeras.qlayers.QDense):
        return f'''
  // Dense {i}

  logic [DENSE5_KD-1:0][DENSE5_KB-1:0] dense{i}_k;
  logic [DENSE5_BD-1:0][DENSE5_KB-1:0] dense{i}_b;
  logic [DENSE5_XD-1:0][DENSE5_XB-1:0] dense{i}_x; 
  logic [DENSE5_YD-1:0][DENSE5_YB-1:0] dense{i}_y;
  qdense #(.YD(DENSE{i}_YD), .XD(DENSE{i}_XD), .XB(DENSE{i}_XB), .KB(DENSE{i}_KB)
    ) DENSE{i} (  
    .k(dense{i}_k),
    .b(dense{i}_b),
    .x(dense{i}_x), 
    .y(dense{i}_y)
  );
        '''

    if isinstance(layer, qkeras.qlayers.QActivation):
        return f'''
  // Act {i}

  logic [ACT{i}_D-1:0][ACT{i}_XB-1:0] act{i}_x;
  logic [ACT{i}_D-1:0][ACT{i}_YB-1:0] act{i}_y;
  qact #(.N(ACT{i}_D), .XB(ACT{i}_XB), .XBF(ACT{i}_XBF), .YBQ(ACT{i}_YBQ), .YBI(ACT{i}_YBI), .NEGATIVE_SLOPE(ACT{i}_NEGATIVE_SLOPE)
    ) ACT{i} (
    .x(act{i}_x),
    .y(act{i}_y)
  );
        '''


def layer_param(model, i, XB, XBF):
  layer = model.layers[i]

  # Conv
  if isinstance(layer, qkeras.qconvolutional.QConv2D):
    k_config = layer.kernel_quantizer.get_config()
    assert layer.kernel_quantizer.get_config()['bits'] == layer.bias_quantizer.get_config()['bits']

    KH, KW, XC, YC = layer.kernel.shape
    _, XH, XW, XC = layer.input.shape
    SH, SW = layer.strides
    KB = k_config['bits']

    return f'''
  localparam
    CONV{i}_XB={XB}, CONV{i}_KB={KB},
    CONV{i}_XH={XH}, CONV{i}_XW={XW}, CONV{i}_XC={XC}, CONV{i}_YC={YC},
    CONV{i}_KH={KH}, CONV{i}_KW={KW}, CONV{i}_SH={SH}, CONV{i}_SW={SW},
    CONV{i}_YH=CONV{i}_XH/CONV{i}_SH, CONV{i}_YW=CONV{i}_XW/CONV{i}_SW,
    CONV{i}_YB=CONV{i}_XB+CONV{i}_KB + $clog{i}(CONV{i}_KH*CONV{i}_KW*CONV{i}_XC+1),
    CONV{i}_XD=CONV{i}_XH*CONV{i}_XW*CONV{i}_XC,
    CONV{i}_KD=CONV{i}_KH*CONV{i}_KW*CONV{i}_XC*CONV{i}_YC, CONV{i}_BD=CONV{i}_YC,
    CONV{i}_YD=CONV{i}_YH*CONV{i}_YW*CONV{i}_YC,'''

  # Dense
  if isinstance(layer, qkeras.qlayers.QDense):
    k_config = layer.kernel_quantizer.get_config()
    assert layer.kernel_quantizer.get_config()['bits'] == layer.bias_quantizer.get_config()['bits']

    XD, YD = model.layers[5].kernel.shape
    KB = k_config['bits']
    return f'''
  localparam
    DENSE{i}_XD={XD}, DENSE{i}_YD={YD}, DENSE{i}_KB={KB}, DENSE{i}_XB={XB},
    DENSE{i}_YB=DENSE{i}_XB + DENSE{i}_KB + $clog2(DENSE{i}_XD+1),
    DENSE{i}_KD=DENSE{i}_XD*DENSE{i}_YD, DENSE{i}_BD=DENSE{i}_YD,'''

  #Act
  if isinstance(layer, qkeras.qlayers.QActivation):
    config = layer.get_config()['activation'].get_config()
    D = np.array(layer.input.shape[1:]).prod()
    YB = config['bits']
    YBI = config['integer']
    NEGATIVE_SLOPE = int(config['negative_slope']* 2**(YB-YBI-(config['negative_slope']!=0)))

    return f'''
  localparam
    ACT{i}_XB={XB}, ACT{i}_XBF={XBF}, ACT{i}_YBQ={YB}, ACT{i}_YBI={YBI}, ACT{i}_D={D}, 
    ACT{i}_NEGATIVE_SLOPE={NEGATIVE_SLOPE},
    ACT{i}_YB=ACT{i}_YBQ+(ACT{i}_NEGATIVE_SLOPE==0),'''


def make_verilog_array(arr, bits):
    txt = ""
    for w in arr[::-1]:
        sign = "-" if w < 0 else ""
        txt += f" {sign}{bits}'d{abs(w)},"
    return txt[:-1]



if __name__ == '__main__':
   
    '''
    Load Model
    '''
    with open('encoder_8x8_c8_S2_tele_qK_6bit.json') as json_file:
        data = json.load(json_file)
    data = json.dumps(data)
    model = qkeras.utils.quantized_model_from_json(data)

    '''
    Generate Input
    '''
    tf.random.set_seed(0)
    x_shape = np.array(model.input.shape)
    x_shape[0] = 1
    x = tf.random.normal(x_shape.tolist())

    print(x.shape)

    '''
    Save input, output txt files
    '''

    get_act_txt(model, 1, 'x')
    get_act_txt(model, len(model.layers)-1, 'y6_exp')

    localparam = ""
    body = ""
    chain = ""
    weights_list = []
    weights_bits = 0
    weight_assign_list = []
    first = None
    prev = None
    for i, layer in enumerate(model.layers):

        '''
        LAYER TYPE
        '''
        if isinstance(layer, qkeras.qconvolutional.QConv2D):
            layer_type = 'conv'
        elif isinstance(layer, qkeras.qlayers.QDense):
            layer_type = 'dense'
        elif isinstance(layer, qkeras.qlayers.QActivation):
            layer_type = 'act'
        else:
            layer_type = None

        if i > 1 and layer_type is not None:
            body += layer_rtl(model, i)
            localparam += layer_param(model, i, XB, XBF)

            '''
            CHAINING
            '''
            if first is None and layer_type != 'act':
                first = f"{layer_type}{i}"
                chain = f"\n  assign {first}_x = x;"
            else:
                chain += f"\n  assign {layer_type}{i}_x = {prev}_y;"
            prev = f"{layer_type}{i}"

        '''
        NEXT BITS
        '''
        if layer_type=='act':
            config = layer.get_config()['activation'].get_config()

            if prev:
                XB = f'{prev.upper()}_YB'
            else:
                XB = config['bits']
            if 'keep_negative' in config:
                XB += (config['keep_negative']==0)

            XBF = config['bits'] - config['integer']
            if 'keep_negative' in config:
                XBF -= config['keep_negative']
            elif 'negative_slope' in config:
                XBF -= config['negative_slope']!=0
        else:
            if prev:
                XB = f'{prev.upper()}_YB'
        
        '''
        WEIGHTS
        '''
        if layer_type in ['dense', 'conv']:
            k_config = layer.kernel_quantizer.get_config()
            KF = k_config['bits']-k_config['integer']-k_config['keep_negative']
            XBF = XBF + KF

            k = np.array(layer.kernel_quantizer_internal(layer.kernel) * 2**KF).astype(int)
            b = np.array(layer.bias_quantizer_internal  (layer.bias  ) * 2**KF).astype(int)
            kb = np.concatenate([k.flatten(), b.flatten()])
            weights_bits += kb.size * k_config['bits']

            weights_list.insert(0, make_verilog_array(arr=kb, bits=k_config['bits']))
            weight_assign_list.insert(0, f"{layer_type}{i}_k")
            weight_assign_list.insert(0, f"{layer_type}{i}_b")

    with open('../../rtl/model.sv', 'w') as f:
        f.write(f'''
module model #(
{localparam}
  localparam
    XD={first.upper()}_XD, XB={first.upper()}_XB, 
    YD={prev.upper()}_D, YB={prev.upper()}_YB,
    WEIGHTS_B = {weights_bits}
)(
  input  logic clk, rstn, en,
  input  logic [XD-1:0][XB-1:0] x,
  output logic [YD-1:0][YB-1:0] y
);
  // TMR Weights
  
  wire [WEIGHTS_B-1:0] weights_d = {{ {', '.join(weights_list)} }};
  wire [WEIGHTS_B-1:0] weights_q;
  register #(.W(WEIGHTS_B)) TMR_REG (.clk(clk), .rstn(rstn), .en(en), .d(weights_d), .q(weights_q));
  {body}
  assign {{{', '.join(weight_assign_list)}}} = weights_q;
  {chain}
  assign y = {prev}_y;

endmodule''')
