

int get_id(vec2 uv){
    return int(floor(texture2D(IDS, uv).r + 0.5));
}

bool is_hand_or_handheld(int mat) {
    return mat >= IN_HAND_DEFAULT && mat <= IN_HAND_ALL;
}

bool is_block(int mat) {
    return mat >= BLOCKS_DEFAULT && mat <= BLOCKS_ALL;
}

bool is_mob(int mat) {
    return mat >= MOBS_DEFAULT && mat <= MOBS_ALL;
}

bool is_non_mob_entity(int mat) {
    return mat >= ENTITIES_DEFAULT && mat <= ENTITIES_ALL;
}

float get_handheld_texture_multiplier(int hhid){
    switch(hhid){
        case 30001: return 16.0;
        default: return 32.0;
    }
}

float get_entity_texture_multiplier(int eid){
    switch(eid){
        default: return 8.0;
    }
}