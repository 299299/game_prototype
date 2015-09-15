

enum RootMotionFlag
{
    kMotion_None         = 0,
    kMotion_X   = (1 << 0),
    kMotion_Y   = (1 << 1),
    kMotion_Z   = (1 << 2),
    kMotion_R   = (1 << 3),
    kMotion_XZR = kMotion_X | kMotion_Z | kMotion_R,
    kMotion_XZ  = kMotion_X | kMotion_Z,
    kMotion_XR  = kMotion_X | kMotion_R,
    kMotion_ZR  = kMotion_Z | kMotion_R,
};

const String TITLE = "AssetProcess";
const String TranslateBoneName = "Bip01_$AssimpFbx$_Translation";
const String RotateBoneName = "Bip01_$AssimpFbx$_Rotation";
const String ScaleBoneName = "Bip01_$AssimpFbx$_Scaling";
const String rigName = "Models/bruce.mdl";

Scene@  processScene;
Node@   processNode;
Node@   translateNode;
Node@   rotateNode;

Vector3 pelvisRightAxis = Vector3(1, 0, 0);
Quaternion rotateBoneInitQ;
Vector3 pelvisOrign;

Vector3 GetProjectedAxis(Node@ node, const Vector3&in axis)
{
    Vector3 p = node.worldRotation * axis;
    p.Normalize();
    Vector3 ret = processNode.worldRotation.Inverse() * p;
    ret.Normalize();
    ret.y = 0;
    return ret;
}

Quaternion GetRotationInXZPlane(Node@ rotateNode, const Quaternion&in startLocalRot, const Quaternion&in curLocalRot)
{
    rotateNode.rotation = startLocalRot;
    Vector3 startAxis = GetProjectedAxis(rotateNode, pelvisRightAxis);
    rotateNode.rotation = curLocalRot;
    Vector3 curAxis = GetProjectedAxis(rotateNode, pelvisRightAxis);
    return Quaternion(startAxis, curAxis);
}

void PreProcess()
{
    processScene = Scene();
    processNode = processScene.CreateChild("Character");
    AnimatedModel@ am = processNode.CreateComponent("AnimatedModel");
    am.model = cache.GetResource("Model", rigName);

    Skeleton@ skel = am.skeleton;
    Bone@ bone = skel.GetBone("RootNode");
    // bone.initialRotation = Quaternion(0, -180, 0);
    // skel.GetBone("RootNode").initialRotation = Quaternion(0, -180, 0);

    bone = skel.GetBone(RotateBoneName);
    rotateBoneInitQ = bone.initialRotation;
    pelvisRightAxis = rotateBoneInitQ * Vector3(1, 0, 0);
    Print("pelvisRightAxis = " + pelvisRightAxis.ToString());

    translateNode = processNode.GetChild(TranslateBoneName, true);
    rotateNode = processNode.GetChild(RotateBoneName, true);
    pelvisOrign = skel.GetBone(TranslateBoneName).initialPosition;
}

void ProcessAnimation(const String&in animationFile, int motionFlag, int originFlag, int allowMotion, bool cutRotation, Array<Vector4>&out outKeys, bool dump = false)
{
    Print("Processing animation " + animationFile);

    Animation@ anim = cache.GetResource("Animation", animationFile);
    if (anim is null) {
        ErrorDialog(TITLE, animationFile + " not found!");
        engine.Exit();
        return;
    }

    AnimationTrack@ translateTrack = anim.tracks[TranslateBoneName];
    AnimationTrack@ rotateTrack = anim.tracks[RotateBoneName];

    // ==============================================================
    // pre process key frames
    if (translateTrack !is null)
    {
        Quaternion q(0, 180, 0); // hack !!!
        for (uint i=0; i<translateTrack.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf(translateTrack.keyFrames[i]);
            kf.position = q * kf.position;
            translateTrack.keyFrames[i] = kf;
            // Print("RotateOrigin change pos from " + oldPos.ToString() + " to " + kf.position_.ToString());
        }
    }

    if (originFlag & kMotion_R != 0)
    {
        Quaternion q(0, 180, 0); // hack !!!
        if (rotateTrack !is null)
        {
            for (uint i=0; i<rotateTrack.numKeyFrames; ++i)
            {
                AnimationKeyFrame kf(rotateTrack.keyFrames[i]);
                rotateNode.rotation = kf.rotation;
                Quaternion wq = rotateNode.worldRotation;
                wq = q * wq;
                rotateNode.worldRotation = wq;
                kf.rotation = rotateNode.rotation;
                rotateTrack.keyFrames[i] = kf;
            }
        }
        if (translateTrack !is null)
        {
            for (uint i=0; i<translateTrack.numKeyFrames; ++i)
            {
                AnimationKeyFrame kf(translateTrack.keyFrames[i]);
                kf.position = q * kf.position;
                translateTrack.keyFrames[i] = kf;
                // Print("RotateOrigin change pos from " + oldPos.ToString() + " to " + kf.position_.ToString());
            }
        }
    }

    outKeys.Resize(translateTrack.numKeyFrames);

    float firstRotateFromRoot = 0;
    if (rotateTrack !is null)
    {
        for (uint i=0; i<rotateTrack.numKeyFrames; ++i)
        {
            Quaternion q = GetRotationInXZPlane(rotateNode, rotateBoneInitQ, rotateTrack.keyFrames[i].rotation);
            if (i == 0 || i == rotateTrack.numKeyFrames - 1)
                Print("frame=" + String(i) + " rotation from identical in xz plane=" + q.eulerAngles.ToString());
            if (i == 0)
                firstRotateFromRoot = q.eulerAngles.y;
        }
    }

    // process rotate key frames first
    if ((motionFlag & kMotion_R != 0) && rotateTrack !is null)
    {
        Quaternion lastRot = rotateTrack.keyFrames[0].rotation;
        float rotateFromStart = cutRotation ? firstRotateFromRoot : 0;
        for (uint i=0; i<rotateTrack.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf(rotateTrack.keyFrames[i]);
            Quaternion q = GetRotationInXZPlane(rotateNode, lastRot, kf.rotation);
            lastRot = kf.rotation;
            if (dump)
                Print("rotation from last frame = " + String(q.eulerAngles.y));

            outKeys[i].w = rotateFromStart;
            rotateFromStart += q.eulerAngles.y;

            q = Quaternion(0, rotateFromStart, 0);
            Quaternion wq = rotateNode.worldRotation;
            wq = q.Inverse() * wq;
            rotateNode.worldRotation = wq;
            kf.rotation = rotateNode.rotation;
            rotateTrack.keyFrames[i] = kf;
        }
    }

    originFlag &= (~kMotion_R);
    if (originFlag != 0 && translateTrack !is null)
    {
        Vector3 firstKeyPos = translateTrack.keyFrames[0].position;
        translateNode.position = firstKeyPos;
        Vector3 currentWS = translateNode.worldPosition;
        Vector3 oldWS = currentWS;

        if (originFlag & kMotion_X != 0)
            currentWS.x = pelvisOrign.x;
        if (originFlag & kMotion_Y != 0)
            currentWS.y = pelvisOrign.y;
        if (originFlag & kMotion_Z != 0)
            currentWS.z = pelvisOrign.z;

        translateNode.worldPosition = currentWS;
        Vector3 currentLS = translateNode.position;
        Vector3 originDiffLS = currentLS - firstKeyPos;
        Print("originDiffLS = " + originDiffLS.ToString() + " oldWS=" + oldWS.ToString());

        for (uint i=0; i<translateTrack.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf(translateTrack.keyFrames[i]);
            Vector3 old = kf.position;
            kf.position += originDiffLS;
            // Print("MoveToOrigin from " + old.ToString() + " to " + kf.position_.ToString());
            translateTrack.keyFrames[i] = kf;
        }
    }

    motionFlag &= (~kMotion_R);
    if (motionFlag != 0 && translateTrack !is null)
    {
        Vector3 firstKeyPos = translateTrack.keyFrames[0].position;

        for (uint i=0; i<translateTrack.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf(translateTrack.keyFrames[i]);
            translateNode.position = firstKeyPos;
            Vector3 t1_ws = translateNode.worldPosition;
            translateNode.position = kf.position;
            Vector3 t2_ws = translateNode.worldPosition;
            Vector3 translation = t2_ws - t1_ws;
            if (motionFlag & kMotion_X != 0)
            {
                outKeys[i].x = translation.x;
                t2_ws.x  = t1_ws.x;
            }
            if (motionFlag & kMotion_Y != 0)
            {
                outKeys[i].y = translation.y;
                t2_ws.y = t1_ws.y;
            }
            if (motionFlag & kMotion_Z != 0)
            {
                outKeys[i].z = translation.z;
                t2_ws.z = t1_ws.z;
            }

            translateNode.worldPosition = t2_ws;
            Vector3 local_pos = translateNode.position;
            // Print("local position from " + kf.position.ToString() + " to " + local_pos.ToString());
            kf.position = local_pos;
            translateTrack.keyFrames[i] = kf;
        }
    }

    for (uint i=0; i<outKeys.length; ++i)
    {
        if (allowMotion & kMotion_X == 0)
            outKeys[i].x = 0;
        if (allowMotion & kMotion_Y == 0)
            outKeys[i].y = 0;
        if (allowMotion & kMotion_Z == 0)
            outKeys[i].z = 0;
        if (allowMotion & kMotion_R == 0)
            outKeys[i].w = 0;
    }


    if (dump)
    {
        for (uint i=0; i<outKeys.length; ++i)
        {
            Print("Frame " + String(i) + " motion-key=" + outKeys[i].ToString());
        }
    }


}

void PostProcess()
{
    @rotateNode = null;
    @translateNode = null;
    @processNode = null;
    @processScene = null;
}