//
//  Facer.h
//  VisioninDemo
//
//  Created by Mac on 2017/2/21.
//  Copyright © 2017年 Rex. All rights reserved.
//

#ifndef Facer_h
#define Facer_h

typedef struct st_rect_t {
    int left;   ///< 矩形最左边的坐标
    int top;    ///< 矩形最上边的坐标
    int right;  ///< 矩形最右边的坐标
    int bottom; ///< 矩形最下边的坐标
} vs_rect_t;
/// st float type point definition
typedef struct st_pointf_t {
    float x;    ///< 点的水平方向坐标，为浮点数
    float y;    ///< 点的竖直方向坐标，为浮点数
} vs_pointf_t;
typedef struct vs_models_106_t {
    vs_rect_t rect;         ///< 代表面部的矩形区域
    float score;            ///< 置信度
    vs_pointf_t points_array[106];  ///< 人脸106关键点的数组
    float yaw;              ///< 水平转角，真实度量的左负右正
    float pitch;            ///< 俯仰角，真实度量的上负下正
    float roll;             ///< 旋转角，真实度量的左负右正
    float eye_dist;         ///< 两眼间距
    int ID;                 ///< faceID
} vs_models_106_t;
typedef struct vs_models_face_action_t {
    struct vs_models_106_t face;    /// 人脸信息，包含矩形、106点、pose信息等
    unsigned int face_action;       /// 脸部动作
} vs_models_face_action_t;
#define VS_FACE_DETECT      0x00000001    ///<  人脸检测
#define VS_EYE_BLINK        0x00000002    ///<  眨眼
#define VS_MOUTH_AH         0x00000004    ///<  嘴巴大张
#define VS_HEAD_YAW         0x00000008    ///<  摇头
#define VS_HEAD_PITCH       0x00000010    ///<  点头
#define VS_BROW_JUMP        0x00000020    ///<  眉毛挑动
typedef struct vs_models_human_action_t {
    vs_models_face_action_t faces[10];   /// 检测到的人脸及动作数组
    int face_count;                                                         /// 检测到的人脸数目
} vs_models_human_action_t;

#if __cplusplus
extern "C" {
#endif

    vs_models_human_action_t* GetFacerAction();
    void TestFUCK();
    
#if __cplusplus
}   // Extern C
#endif

#endif /* Facer_h */
