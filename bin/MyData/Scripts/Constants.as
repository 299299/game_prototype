// ==============================================
//
//    constants defination
//
// ==============================================

const int FLAGS_MOVING = (1 << 0);
const int FLAGS_RUN  = (1 << 1);

const int COLLISION_LAYER_LANDSCAPE = (1 << 0);
const int COLLISION_LAYER_CHARACTER = (1 << 1);
const int COLLISION_LAYER_PROP      = (1 << 2);
const int COLLISION_LAYER_RAGDOLL   = (1 << 3);
const int COLLISION_LAYER_AI        = (1 << 4);
const int COLLISION_LAYER_RAYCAST   = (1 << 5);