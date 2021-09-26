function atlas_table = atlas_def()

atlas_struct.atlas_file_name = {'BN_Atlas_246_1mm','Schaefer2018_200Parcels_7Networks_order_FSLMNI152_1mm','Schaefer2018_400Parcels_17Networks_order_FSLMNI152_1mm','HarvardOxford-sub-maxprob-thr25-1mm'}';
atlas_struct.atlas_short_name = {'Brainnetome','Schaefer7_200','Schaefer17_400','HarvardOxford'}';
atlas_table = struct2table(atlas_struct);