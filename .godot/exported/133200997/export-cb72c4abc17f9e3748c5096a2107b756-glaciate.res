RSRC                  	   Resource            ��������   Card                                                   resource_local_to_scene    resource_name    script 
   card_name 
   card_cost    card_sprite    card_description    card_effects    card_targeting_type    card_targeting 	   card_aoe    card_targeting_modifier    card_skill_type    card_action_type       Script    res://scripts/card.gd ��������
   Texture2D 8   res://sprites/card_art/elementalist/CardArtGlaciate.png �cw{�Y      local://Resource_xt8dg $      	   Resource                       	   Glaciate                            N   Deal 10 damage.
Inflict 2 Chill.
Deal 10 more damage if the target is Frozen.    "         damage-10+type:mag    status-2+id:chill %   damage-10+type:mag,has_status:frozen           	         
                                      RSRC