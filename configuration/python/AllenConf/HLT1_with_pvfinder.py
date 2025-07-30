from AllenConf.HLT1 import setup_hlt1_node as original_setup_hlt1_node
from AllenCore.algorithms import PVFinder_t
from AllenCore.generator import make_algorithm
from PyConf.control_flow import CompositeNode, NodeLogic
from AllenConf.utils import initialize_number_of_events

def setup_hlt1_node_with_pvfinder(**kwargs):
    # Call the original setup function
    hlt1_config = original_setup_hlt1_node(**kwargs)
    
    # Get the original node and reconstructed objects
    original_node = hlt1_config['control_flow_node']
    reconstructed_objects = hlt1_config['reconstruction']
    
    # Initialize number of events
    number_of_events = initialize_number_of_events()
    
    # Create PV Finder algorithm
    pvfinder = make_algorithm(
        PVFinder_t,
        name="pvfinder",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_velo_tracks_view_t=reconstructed_objects["velo_tracks"]["dev_velo_tracks_view"],
        dev_velo_states_view_t=reconstructed_objects["velo_states"]["dev_velo_kalman_beamline_states_view"],
    )
    
    # Add PV Finder to the list of algorithms
    if isinstance(original_node, CompositeNode):
        new_children = []
        velo_done = False
        existing_pv_done = False
        for child in original_node.children:
            new_children.append(child)
            if 'velo' in child.name.lower():
                velo_done = True
            if 'pv_' in child.name.lower():
                existing_pv_done = True
            if velo_done and existing_pv_done and not any('pv_' in c.name.lower() for c in new_children[-5:]):
                new_children.append(pvfinder)
                break
        
        if pvfinder not in new_children:
            # If we couldn't find a good spot, add it to the end
            new_children.append(pvfinder)
        
        # Use NodeLogic.NONLAZY_AND as default if 'logic' attribute is not present
        node_logic = getattr(original_node, 'logic', NodeLogic.NONLAZY_AND)
        
        new_node = CompositeNode(
            "HLT1WithPVFinder",
            new_children,
            node_logic,
            force_order=getattr(original_node, 'force_order', True)
        )
    else:
        print("Original node is not a CompositeNode, cannot modify")
        return hlt1_config
            
    # Update the hlt1_config with the new node
    hlt1_config['control_flow_node'] = new_node
    hlt1_config['pvfinder'] = pvfinder
    
    return hlt1_config