set_global_routing_layer_adjustment met1 0.05
set_global_routing_layer_adjustment met2 0.05
set_global_routing_layer_adjustment met3 0.05
set_global_routing_layer_adjustment met4 0.05
set_global_routing_layer_adjustment met5 0.05
set_global_routing_layer_adjustment $::env(MIN_ROUTING_LAYER)-$::env(MAX_ROUTING_LAYER) 0.08

set_routing_layers -clock $::env(MIN_CLK_ROUTING_LAYER)-$::env(MAX_ROUTING_LAYER)
set_routing_layers -signal $::env(MIN_ROUTING_LAYER)-$::env(MAX_ROUTING_LAYER)
