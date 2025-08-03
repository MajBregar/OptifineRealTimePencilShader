

int get_id(vec2 uv){
    return int(floor(texture2D(IDS, uv).r + 0.5));
}

bool allowed_self_contour_detection(int material){

    if (material == CROSS_PLANTS) return false;
    if (material == CROSS_MISC) return false;
    if (material == LEAVES) return false;
    if (material == WATER) return false;
    if (material == MOBS) return false;

    return true;
}