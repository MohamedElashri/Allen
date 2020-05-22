from PVSequence import make_pvs

pvs = make_pvs()
pvs["dev_multi_final_vertices"].producer.configuration().apply()
