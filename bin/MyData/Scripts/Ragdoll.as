// CreateRagdoll script object class

enum RagdollBoneType
{
    BONE_HEAD,
    BONE_PELVIS,
    BONE_SPINE,
    BONE_L_THIGH,
    BONE_R_THIGH,
    BONE_L_CALF,
    BONE_R_CALF,
    BONE_L_UPPERARM,
    BONE_R_UPPERARM,
    BONE_L_FOREARM,
    BONE_R_FOREARM,
    BONE_L_HAND,
    BONE_R_HAND,
    BONE_L_FOOT,
    BONE_R_FOOT,
    RAGDOLL_BONE_NUM
};

enum RagdollState
{
    RAGDOLL_NONE,
    RAGDOLL_STATIC,
    RAGDOLL_DYNAMIC,
    RAGDOLL_BLEND_TO_ANIMATION,
};

const StringHash RAGDOLL_STATE("Ragdoll_State");
const StringHash RAGDOLL_PERPARE("Ragdoll_Prepare");
const StringHash RAGDOLL_START("Ragdoll_Start");
const StringHash RAGDOLL_STOP("Ragdoll_Stop");
const StringHash RAGDOLL_ROOT("Ragdoll_Root");
const StringHash VELOCITY("Velocity");
const StringHash POSITION("Position");

bool blend_to_anim = false;
int ragdoll_method = 2;

class Ragdoll : ScriptObject
{
    Array<Node@>      boneNodes;
    Array<Vector3>    boneLastPositions;
    Array<Quaternion> boneLastRotations;
    Node@             rootNode;

    int               state = RAGDOLL_NONE;
    int               stateRequest = -1;
    bool              hasVelRequest = false;
    Vector3           velocityRequest = Vector3(0, 0, 0);
    Vector3           hitPosition;

    float             timeInState;

    Animation@        blendingAnim_1;
    Animation@        blendingAnim_2;

    float             ragdollToAnimBlendTime = 1.0f;
    float             minRagdollStateTime = 1.5f;
    float             maxRagdollStateTime = 5.0f;

    int               getUpIndex = 0;

    void Start()
    {
        Array<String> boneNames =
        {
            "Bip01_Head",
            "Bip01_Pelvis",//"Bip01_$AssimpFbx$_Translation",
            "Bip01_Spine1",
            "Bip01_L_Thigh",
            "Bip01_R_Thigh",
            "Bip01_L_Calf",
            "Bip01_R_Calf",
            "Bip01_L_UpperArm",
            "Bip01_R_UpperArm",
            "Bip01_L_Forearm",
            "Bip01_R_Forearm",
            "Bip01_L_Hand",
            "Bip01_R_Hand",
            "Bip01_L_Foot",
            "Bip01_R_Foot",
            // ----------------- end of ragdoll bone -------------------
            "Bip01_$AssimpFbx$_Translation",
            "Bip01_$AssimpFbx$_Rotation",
            "Bip01_$AssimpFbx$_PreRotation",
            "Bip01_Pelvis",
            "Bip01_Spine",
            "Bip01_Spine2",
            "Bip01_Spine3",
            "Bip01_Neck",
            "Bip01_L_Clavicle",
            "Bip01_R_Clavicle",
            "Bip01"
        };

        rootNode = node;

        int maxLen = RAGDOLL_BONE_NUM;
        if (blend_to_anim)
            maxLen = boneNames.length;

        boneNodes.Resize(maxLen);
        boneLastPositions.Resize(maxLen);

        if (blend_to_anim)
            boneLastRotations.Resize(maxLen);

        for (int i=0; i<maxLen; ++i)
        {
            boneNodes[i] = node.GetChild(boneNames[i], true);
            boneNodes[i].vars[NODE] = node.id;
        }

        Node@ renderNode = node;
        AnimatedModel@ model = node.GetComponent("AnimatedModel");
        if (model is null)
            renderNode = node.GetChild("RenderNode", false);

        if (blend_to_anim)
        {
            blendingAnim_1 = cache.GetResource("Animation", GetAnimationName("TG_Getup/GetUp_Back"));
            blendingAnim_2 = cache.GetResource("Animation", GetAnimationName("TG_Getup/GetUp_Front"));
        }

        SubscribeToEvent(renderNode, "AnimationTrigger", "HandleAnimationTrigger");

        if (ragdoll_method != 2)
        {
            CreateRagdoll();
            SetPhysicsEnabled(false);
        }
    }

    void Stop()
    {
        DestroyRagdoll();
        boneNodes.Clear();
    }

    void SetPhysicsEnabled(bool bEnable)
    {
        if (ragdoll_method == 0)
        {
            EnableRagdoll(bEnable);
        }
        else if (ragdoll_method == 1)
        {
            SetRagdollDynamic(bEnable);
            uint mask = COLLISION_LAYER_PROP | COLLISION_LAYER_LANDSCAPE;
            if (bEnable)
                mask |= COLLISION_LAYER_RAGDOLL;
            SetCollisionMask(mask);
        }
        else if (ragdoll_method == 2)
        {
            if (bEnable)
                CreateRagdoll();
            else
                DestroyRagdoll();
        }
    }

    void ChangeState(int newState)
    {
        if (state == newState)
            return;

        int old_state = state;
        LogPrint(rootNode.name + " RagdollComponent ChangeState from " + old_state + " to " + newState);
        state = newState;

        if (newState == RAGDOLL_STATIC)
        {
            for (uint i=0; i<RAGDOLL_BONE_NUM; ++i)
            {
                boneLastPositions[i] = boneNodes[i].worldPosition;
            }
        }
        else if (newState == RAGDOLL_DYNAMIC)
        {
            SetAnimationEnabled(false);
            SetPhysicsEnabled(true);

            if (timeInState > 0.033f)
            {
                for (uint i=0; i<RAGDOLL_BONE_NUM; ++i)
                {
                    RigidBody@ rb = boneNodes[i].GetComponent("RigidBody");
                    if (rb !is null)
                    {
                        Vector3 velocity = boneNodes[i].worldPosition - boneLastPositions[i];
                        float scale = rootNode.vars[TIME_SCALE].GetFloat();
                        velocity /= timeInState;
                        velocity *= scale;
                        velocity *= 1.5f;
                        // LogPrint(boneNodes[i].name + " velocity=" + velocity.ToString());
                        // if (i == BONE_PELVIS || i == BONE_SPINE)
                        rb.linearVelocity = velocity;
                    }
                }
            }

            if (hasVelRequest)
            {
                for (uint i=0; i<RAGDOLL_BONE_NUM; ++i)
                {
                    RigidBody@ rb = boneNodes[i].GetComponent("RigidBody");
                    if (rb !is null)
                    {
                        Vector3 pos = boneNodes[i].worldPosition;
                        float y_diff = Abs(pos.y - hitPosition.y);
                        if (d_log)
                            LogPrint("Ragdoll -- " + boneNodes[i].name + " y_diff = " + y_diff);
                        if (y_diff < 1.0f)
                            rb.linearVelocity = velocityRequest;
                    }
                }
                velocityRequest = Vector3(0, 0, 0);
                hasVelRequest = false;
            }
        }
        else if (newState == RAGDOLL_BLEND_TO_ANIMATION)
        {
            SetPhysicsEnabled(false);
            SetAnimationEnabled(true);
            ResetBonePositions();

            for (uint i=0; i<boneNodes.length; ++i)
            {
                boneLastPositions[i] = boneNodes[i].position;
                boneLastRotations[i] = boneNodes[i].rotation;
                LogPrint(boneNodes[i].name + " last-position=" + boneLastPositions[i].ToString() + " last-rotation=" + boneLastRotations[i].eulerAngles.ToString());
            }
        }
        else if (newState == RAGDOLL_NONE)
        {
            SetPhysicsEnabled(false);
            SetAnimationEnabled(true);
            ResetBonePositions();
        }

        rootNode.vars[RAGDOLL_STATE] = newState;
        timeInState = 0.0f;
    }

    void FixedUpdate(float dt)
    {
        if (stateRequest >= 0) {
            ChangeState(stateRequest);
            stateRequest = -1;
        }

        if (state == RAGDOLL_STATIC)
        {
            timeInState += dt;
        }
        else if (state == RAGDOLL_DYNAMIC)
        {
            // LogPrint("Ragdoll Dynamic time " + timeInState);
            timeInState += dt;

            uint num_of_freeze_objects = 0;
            for (uint i=0; i<RAGDOLL_BONE_NUM; ++i)
            {
                // Vector3 curPos = boneNodes[i].worldPosition;
                RigidBody@ rb = boneNodes[i].GetComponent("RigidBody");
                if (rb is null || !rb.active) {
                    num_of_freeze_objects ++;
                    continue;
                }

                Vector3 vel = rb.linearVelocity;
                if (vel.lengthSquared < 0.1f)
                    num_of_freeze_objects ++;
                //LogPrint(boneNodes[i].name + " vel=" + vel.ToString());
            }

            // LogPrint("num_of_freeze_objects=" + num_of_freeze_objects);
            if (num_of_freeze_objects == RAGDOLL_BONE_NUM && timeInState >= minRagdollStateTime)
                ChangeState(blend_to_anim ? RAGDOLL_BLEND_TO_ANIMATION : RAGDOLL_NONE);
            else if (timeInState > maxRagdollStateTime)
                ChangeState(blend_to_anim ? RAGDOLL_BLEND_TO_ANIMATION : RAGDOLL_NONE);
        }
        else if (state == RAGDOLL_BLEND_TO_ANIMATION)
        {
            //compute the ragdoll blend amount in the range 0...1
            float ragdollBlendAmount = timeInState / ragdollToAnimBlendTime;
            ragdollBlendAmount = Clamp(ragdollBlendAmount, 0.0f, 1.0f);

            timeInState += dt;

            Animation@ anim = blendingAnim_1;
            if (getUpIndex == 1)
                anim = blendingAnim_2;

            for (uint i=0; i<boneNodes.length; ++i)
            {
                AnimationTrack@ track = anim.tracks[boneNodes[i].name];
                if (track is null)
                    continue;

                Node@ n = boneNodes[i];
                Vector3 src_position = boneLastPositions[i];
                Vector3 dst_position = track.keyFrames[0].position;

                Quaternion src_rotation = boneLastRotations[i];
                Quaternion dst_rotation = track.keyFrames[0].rotation;

                n.position = src_position.Lerp(dst_position, ragdollBlendAmount);
                n.rotation = src_rotation.Slerp(dst_rotation, ragdollBlendAmount);
            }

            //if the ragdoll blend amount has decreased to zero, move to animated state
            if (ragdollBlendAmount >= 0.9999999f)
                ChangeState(RAGDOLL_NONE);
        }
    }

    void CreateRagdoll()
    {
        // uint t = time.systemTime;

        // Create RigidBody & CollisionShape components to bones
        Quaternion identityQ(0, 0, 0);
        Quaternion common_rotation(0, 0, 90); // model exported from 3DS MAX need to roll 90

        Vector3 upper_leg_size(0.2f, 0.45f, 0.2f);
        Vector3 uppper_leg_offset(0.3f, 0.0f, 0.0f);

        Vector3 lower_leg_size(0.175f, 0.55f, 0.175f);
        Vector3 lower_leg_offset(0.25f, -0.025f, 0.0f);

        Vector3 upper_arm_size(0.15f, 0.4f, 0.175f);
        Vector3 upper_arm_offset_left(0.1f, 0.0f, 0.01f);
        Vector3 upper_arm_offset_right(0.1f, 0.0f, -0.01f);

        Vector3 lower_arm_size(0.15f, 0.35f, 0.15f);
        Vector3 lower_arm_offset_left(0.125f, 0.0f, 0.01f);
        Vector3 lower_arm_offset_right(0.125f, 0.0f, -0.01f);

        CreateRagdollBone(BONE_PELVIS, SHAPE_BOX, Vector3(0.3f, 0.2f, 0.25f), Vector3(0.0f, 0.0f, 0.0f), identityQ);
        CreateRagdollBone(BONE_SPINE, SHAPE_BOX, Vector3(0.55f, 0.3f, 0.4f), Vector3(0.2f, 0.0f, 0.0f), identityQ);
        CreateRagdollBone(BONE_HEAD, SHAPE_BOX, Vector3(0.3f, 0.2f, 0.25f), Vector3(0.1f, 0.0f, 0.0f), identityQ);

        CreateRagdollBone(BONE_L_THIGH, SHAPE_CAPSULE, upper_leg_size, uppper_leg_offset, common_rotation);
        CreateRagdollBone(BONE_R_THIGH, SHAPE_CAPSULE, upper_leg_size, uppper_leg_offset, common_rotation);

        CreateRagdollBone(BONE_L_CALF, SHAPE_CAPSULE, lower_leg_size, lower_leg_offset, common_rotation);
        CreateRagdollBone(BONE_R_CALF, SHAPE_CAPSULE, lower_leg_size, lower_leg_offset, common_rotation);

        CreateRagdollBone(BONE_L_UPPERARM, SHAPE_CAPSULE, upper_arm_size, upper_arm_offset_left, common_rotation);
        CreateRagdollBone(BONE_R_UPPERARM, SHAPE_CAPSULE, upper_arm_size, upper_arm_offset_right, common_rotation);

        CreateRagdollBone(BONE_L_FOREARM, SHAPE_CAPSULE, lower_arm_size, lower_arm_offset_left, common_rotation);
        CreateRagdollBone(BONE_R_FOREARM, SHAPE_CAPSULE, lower_arm_size, lower_arm_offset_right, common_rotation);

        // Create Constraints between bones
        CreateRagdollConstraint(boneNodes[BONE_HEAD], boneNodes[BONE_SPINE], CONSTRAINT_CONETWIST,
            Vector3(-1.0f, 0.0f, 0.0f), Vector3(-1.0f, 0.0f, 0.0f), Vector2(0.0f, 30.0f), Vector2(0.0f, 0.0f));

        CreateRagdollConstraint(boneNodes[BONE_L_THIGH], boneNodes[BONE_PELVIS], CONSTRAINT_CONETWIST, Vector3(0.0f, 0.0f, -1.0f),
            Vector3(0.0f, 0.0f, 1.0f), Vector2(45.0f, 45.0f), Vector2(0.0f, 0.0f));
        CreateRagdollConstraint(boneNodes[BONE_R_THIGH], boneNodes[BONE_PELVIS], CONSTRAINT_CONETWIST, Vector3(0.0f, 0.0f, -1.0f),
            Vector3(0.0f, 0.0f, 1.0f), Vector2(45.0f, 45.0f), Vector2(0.0f, 0.0f));
        CreateRagdollConstraint(boneNodes[BONE_L_CALF], boneNodes[BONE_L_THIGH], CONSTRAINT_HINGE, Vector3(0.0f, 0.0f, -1.0f),
            Vector3(0.0f, 0.0f, -1.0f), Vector2(90.0f, 0.0f), Vector2(0.0f, 0.0f));
        CreateRagdollConstraint(boneNodes[BONE_R_CALF], boneNodes[BONE_R_THIGH], CONSTRAINT_HINGE, Vector3(0.0f, 0.0f, -1.0f),
            Vector3(0.0f, 0.0f, -1.0f), Vector2(90.0f, 0.0f), Vector2(0.0f, 0.0f));
        CreateRagdollConstraint(boneNodes[BONE_SPINE], boneNodes[BONE_PELVIS], CONSTRAINT_HINGE, Vector3(0.0f, 0.0f, 1.0f),
            Vector3(0.0f, 0.0f, 1.0f), Vector2(45.0f, 0.0f), Vector2(-10.0f, 0.0f));
        CreateRagdollConstraint(boneNodes[BONE_L_UPPERARM], boneNodes[BONE_SPINE], CONSTRAINT_CONETWIST, Vector3(0.0f, -1.0f, 0.0f),
            Vector3(0.0f, 1.0f, 0.0f), Vector2(45.0f, 45.0f), Vector2(0.0f, 0.0f), false);
        CreateRagdollConstraint(boneNodes[BONE_R_UPPERARM], boneNodes[BONE_SPINE], CONSTRAINT_CONETWIST, Vector3(0.0f, -1.0f, 0.0f),
            Vector3(0.0f, 1.0f, 0.0f), Vector2(45.0f, 45.0f), Vector2(0.0f, 0.0f), false);
        CreateRagdollConstraint(boneNodes[BONE_L_FOREARM], boneNodes[BONE_L_UPPERARM], CONSTRAINT_HINGE, Vector3(0.0f, 0.0f, -1.0f),
            Vector3(0.0f, 0.0f, -1.0f), Vector2(90.0f, 0.0f), Vector2(0.0f, 0.0f));
        CreateRagdollConstraint(boneNodes[BONE_R_FOREARM], boneNodes[BONE_R_UPPERARM], CONSTRAINT_HINGE, Vector3(0.0f, 0.0f, -1.0f),
            Vector3(0.0f, 0.0f, -1.0f), Vector2(90.0f, 0.0f), Vector2(0.0f, 0.0f));

        // LogPrint("CreateRagdoll time-cost=" + (time.systemTime - t) + " ms");
    }

    void CreateRagdollBone(RagdollBoneType boneType, ShapeType type, const Vector3&in size, const Vector3&in position, const Quaternion&in rotation)
    {
        Node@ boneNode = boneNodes[boneType];
        RigidBody@ body = boneNode.CreateComponent("RigidBody");
        // Set mass to make movable
        body.mass = 1.0f;
        // Set damping parameters to smooth out the motion
        body.linearDamping = 0.1f;
        body.angularDamping = 0.85f;
        // Set rest thresholds to ensure the ragdoll rigid bodies come to rest to not consume CPU endlessly
        body.linearRestThreshold = 2.5f;
        body.angularRestThreshold = 1.5f;
        body.collisionLayer = COLLISION_LAYER_RAGDOLL;
        body.collisionMask = COLLISION_LAYER_RAGDOLL | COLLISION_LAYER_PROP | COLLISION_LAYER_LANDSCAPE | COLLISION_LAYER_CHARACTER;
        body.friction = 2.0f;
        body.gravityOverride = Vector3(0, -32, 0);
        body.node.vars[RAGDOLL_ROOT] = rootNode.id;
        // body.kinematic = true;

        //if (boneType == BONE_PELVIS)
        //    body.angularFactor = Vector3(0, 0, 0);

        CollisionShape@ shape = boneNode.CreateComponent("CollisionShape");
        const float ragdoll_size_scale = 100.0f;
        // We use either a box or a capsule shape for all of the bones
        if (type == SHAPE_BOX)
            shape.SetBox(size * ragdoll_size_scale, position * ragdoll_size_scale, rotation);
        else if (type == SHAPE_SPHERE)
            shape.SetSphere(size.x * ragdoll_size_scale, position * ragdoll_size_scale, rotation);
        else
            shape.SetCapsule(size.x * ragdoll_size_scale, size.y * ragdoll_size_scale, position * ragdoll_size_scale, rotation);
    }

    void CreateRagdollConstraint(Node@ boneNode, Node@ parentNode, ConstraintType type,
        const Vector3&in axis, const Vector3&in parentAxis, const Vector2&in highLimit, const Vector2&in lowLimit,
        bool disableCollision = true)
    {
        Constraint@ constraint = boneNode.CreateComponent("Constraint");
        constraint.constraintType = type;
        // Most of the constraints in the ragdoll will work better when the connected bodies don't collide against each other
        constraint.disableCollision = disableCollision;
        // The connected body must be specified before setting the world position
        constraint.otherBody = parentNode.GetComponent("RigidBody");
        // Position the constraint at the child bone we are connecting
        constraint.worldPosition = boneNode.worldPosition;
        // Configure axes and limits
        constraint.axis = axis;
        constraint.otherAxis = parentAxis;
        constraint.highLimit = highLimit;
        constraint.lowLimit = lowLimit;
    }

    void DestroyRagdoll()
    {
        for (uint i=0; i<RAGDOLL_BONE_NUM; ++i)
        {
            boneNodes[i].RemoveComponent("RigidBody");
            boneNodes[i].RemoveComponent("Constraint");
        }
    }

    void EnableRagdoll(bool bEnable)
    {
        for (uint i=0; i<RAGDOLL_BONE_NUM; ++i)
        {
            RigidBody@ rb = boneNodes[i].GetComponent("RigidBody");
            Constraint@ cs = boneNodes[i].GetComponent("Constraint");
            if (rb !is null)
                rb.enabled = bEnable;
            if (cs !is null) {
                cs.enabled = bEnable;
            }
        }
    }

    void SetAnimationEnabled(bool bEnable)
    {
        // Disable keyframe animation from all bones so that they will not interfere with the ragdoll
        AnimatedModel@ model = node.GetComponent("AnimatedModel");

        if (model is null)
            model = node.children[0].GetComponent("AnimatedModel");
        if (model is null)
            return;

        Skeleton@ skeleton = model.skeleton;
        for (uint i = 0; i < skeleton.numBones; ++i)
            skeleton.bones[i].animated = bEnable;

        if (!bEnable)
            model.RemoveAllAnimationStates();
    }

    void SetRagdollDynamic(bool dynamic)
    {
        for (uint i=0; i<RAGDOLL_BONE_NUM; ++i)
        {
            RigidBody@ rb = boneNodes[i].GetComponent("RigidBody");
            if (rb !is null)
                rb.kinematic = !dynamic;
        }
    }

    void SetCollisionMask(uint mask)
    {
        for (uint i=0; i<RAGDOLL_BONE_NUM; ++i)
        {
            RigidBody@ rb = boneNodes[i].GetComponent("RigidBody");
            if (rb !is null)
                rb.collisionMask = mask;
        }
    }

    void HandleAnimationTrigger(StringHash eventType, VariantMap& eventData)
    {
        if (eventData[DATA].type == VAR_VARIANTMAP)
        {
            OnAnimationTrigger(eventData[DATA].GetVariantMap());
        }
    }

    void OnAnimationTrigger(const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        int new_state = RAGDOLL_NONE;
        if (name == RAGDOLL_PERPARE)
            new_state = RAGDOLL_STATIC;
        else if (name == RAGDOLL_START)
            new_state = RAGDOLL_DYNAMIC;
        else if (name == RAGDOLL_STOP)
            new_state = RAGDOLL_NONE;
        else
            return; // other animation events

        stateRequest = new_state;
        if (eventData.Contains(VELOCITY))
        {
            hasVelRequest = true;
            velocityRequest = eventData[VELOCITY].GetVector3();
            hitPosition = eventData[POSITION].GetVector3();
            LogPrint(node.name + " RagdollComponent velocityRequest="+ velocityRequest.ToString() + " hitPosition=" + hitPosition.ToString());
        }
    }

    void ResetBonePositions()
    {
        Node@ pelvis_bone = boneNodes[BONE_PELVIS];
        Quaternion oldRot = pelvis_bone.worldRotation;

        // determine back or frong get up
        Vector3 pelvis_up = oldRot * Vector3(0, 1, 0);
        //LogPrint("pelvis_up=" + pelvis_up.ToString());

        getUpIndex = 0;
        if (pelvis_up.y < 0)
            getUpIndex = 1;

        //LogPrint("getUpIndex = " + getUpIndex);
        rootNode.vars[ANIMATION_INDEX] = getUpIndex;

        Vector3 head_pos = boneNodes[BONE_HEAD].worldPosition;
        Vector3 pelvis_pos = pelvis_bone.worldPosition;

        Vector3 ragdolledDirection = head_pos - pelvis_pos;
        ragdolledDirection.y = 0.0f;
        Vector3 currentDirection = rootNode.worldRotation * Vector3(0, 0, 1);
        currentDirection.y = 0.0f;

        Quaternion dRot;
        dRot.FromRotationTo(currentDirection, ragdolledDirection);
        Quaternion oldRootRot = rootNode.worldRotation;
        Quaternion targetRootRot = oldRootRot * dRot;
        if (getUpIndex == 0)
            targetRootRot = targetRootRot * Quaternion(0, 180, 0);

        Node@ t_node = rootNode.GetChild("Bip01_$AssimpFbx$_Translation", true);
        Node@ r_node = rootNode.GetChild("Bip01_$AssimpFbx$_Rotation", true);
        Vector3 cur_root_pos = rootNode.worldPosition;
        Vector3 dest_root_pos = cur_root_pos;
        dest_root_pos.x = pelvis_pos.x;
        dest_root_pos.z = pelvis_pos.z;

        // Hack!!!
        if (getUpIndex == 0)
        {
            boneNodes[BONE_SPINE].position = Vector3(8.78568, -0.00968838, 0);
            t_node.position = Vector3(-0.0264441, 0.282345, 0.461603);
        }
        else
        {
            boneNodes[BONE_SPINE].position = Vector3(8.78568, -0.00968742, 0);
            t_node.position = Vector3(-0.0246718, 0.465134, -0.135913);
        }

        pelvis_bone.position = Vector3(0, 0, 0);
        rootNode.worldPosition = FilterPosition(dest_root_pos);

        Quaternion q(90, 0, -90);
        pelvis_bone.rotation = q;

        q = oldRot * q.Inverse();
        r_node.worldRotation = q;

        // LogPrint("targetRootRot=" + targetRootRot.eulerAngles.ToString());
        // q = r_node.worldRotation;
        rootNode.worldRotation = targetRootRot;
        r_node.worldRotation = q;
    }
}