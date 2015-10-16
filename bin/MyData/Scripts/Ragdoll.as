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
};

enum RagdollState
{
    RAGDOLL_NONE,
    RAGDOLL_STATIC,
    RAGDOLL_DYNAMIC,
};

const StringHash RAGDOLL_STATE("Ragdoll_State");
const StringHash RAGDOLL_PERPARE("Ragdoll_Prepare");
const StringHash RAGDOLL_START("Ragdoll_Start");
const StringHash RAGDOLL_STOP("Ragdoll_Stop");

class Ragdoll : ScriptObject
{
    Array<Node@>      boneNodes;
    Array<Vector3>    boneLastPositions;
    Node@             rootNode;

    float             scale;
    int               state;
    float             timeInState;

    Ragdoll()
    {
        scale = 100.0f;
        state = RAGDOLL_NONE;
    }

    void Start()
    {
        Array<String> boneNames =
        {
            "Bip01_Head",
            "Bip01_Pelvis",
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
            "Bip01_R_Foot"
        };

        rootNode = node;
        boneNodes.Resize(boneNames.length);
        boneLastPositions.Resize(boneNames.length);

        for (uint i=0; i<boneNames.length; ++i)
        {
            boneNodes[i] = node.GetChild(boneNames[i], true);
            boneLastPositions[i] = boneNodes[i].worldPosition;
        }

        Node@ renderNode = node;
        AnimatedModel@ model = node.GetComponent("AnimatedModel");
        if (model is null)
            renderNode = node.children[0];

        SubscribeToEvent(renderNode, "AnimationTrigger", "HandleAnimationTrigger");
    }

    void Stop()
    {
        boneNodes.Clear();
    }

    void ChangeState(int newState)
    {
        if (state == newState)
            return;

        Print("Ragdoll ChangeState from " + state + " to " + newState);
        state = newState;
        if (newState == RAGDOLL_STATIC)
        {
            for (uint i=0; i<boneNodes.length; ++i)
            {
                boneLastPositions[i] = boneNodes[i].worldPosition;
            }
        }
        else if (newState == RAGDOLL_DYNAMIC)
        {
            SetAnimationEnabled(false);
            CreateRagdoll();

            for (uint i=0; i<boneNodes.length; ++i)
            {
                RigidBody@ rb = boneNodes[i].GetComponent("RigidBody");
                if (rb !is null)
                {
                    Vector3 velocity = boneNodes[i].worldPosition - boneLastPositions[i];
                    float scale = rootNode.vars[TIME_SCALE].GetFloat();
                    velocity /= timeInState;
                    velocity *= scale;
                    Print(boneNodes[i].name + " velocity=" + velocity.ToString());
                    //if (i == BONE_PELVIS || i == BONE_SPINE)
                        rb.linearVelocity = velocity;
                }
            }
        }
        else if (newState == RAGDOLL_NONE)
        {
            DestroyRagdoll();
            SetAnimationEnabled(true);
        }

        rootNode.vars[RAGDOLL_STATE] = newState;
        timeInState = 0.0f;
    }

    void CreateRagdoll()
    {
        uint t = time.systemTime;

        // Create RigidBody & CollisionShape components to bones
        Quaternion identityQ(0, 0, 0);
        Quaternion common_rotation(0, 0, 90); // model exported from 3DS MAX need to roll 90

        Vector3 upper_leg_size(0.2f, 0.45f, 0.2f);
        Vector3 uppper_leg_offset(0.3f, 0.0f, 0.0f);

        Vector3 lower_leg_size(0.175f, 0.55f, 0.175f);
        Vector3 lower_leg_offset(0.25f, 0.0f, 0.0f);

        Vector3 upper_arm_size(0.15f, 0.4f, 0.175f);
        Vector3 upper_arm_offset_left(0.1f, 0.0f, 0.01f);
        Vector3 upper_arm_offset_right(0.1f, 0.0f, -0.01f);

        Vector3 lower_arm_size(0.15f, 0.35f, 0.15f);
        Vector3 lower_arm_offset_left(0.125f, 0.0f, 0.01f);
        Vector3 lower_arm_offset_right(0.125f, 0.0f, -0.01f);

        CreateRagdollBone(boneNodes[BONE_HEAD], SHAPE_CAPSULE, Vector3(0.25f, 0.35f, 0.2f), Vector3(0.0f, 0.0f, 0.0f), common_rotation);
        CreateRagdollBone(boneNodes[BONE_PELVIS], SHAPE_CAPSULE, Vector3(0.4f, 0.3f, 0.25f), Vector3(0.0f, 0.0f, 0.0f), common_rotation);
        CreateRagdollBone(boneNodes[BONE_SPINE], SHAPE_CAPSULE, Vector3(0.4f, 0.55f, 0.3f), Vector3(0.15f, 0.0f, 0.0f), common_rotation);

        CreateRagdollBone(boneNodes[BONE_L_THIGH], SHAPE_CAPSULE, upper_leg_size, uppper_leg_offset, common_rotation);
        CreateRagdollBone(boneNodes[BONE_R_THIGH], SHAPE_CAPSULE, upper_leg_size, uppper_leg_offset, common_rotation);

        CreateRagdollBone(boneNodes[BONE_L_CALF], SHAPE_CAPSULE, lower_leg_size, lower_leg_offset, common_rotation);
        CreateRagdollBone(boneNodes[BONE_R_CALF], SHAPE_CAPSULE, lower_leg_size, lower_leg_offset, common_rotation);

        CreateRagdollBone(boneNodes[BONE_L_UPPERARM], SHAPE_CAPSULE, upper_arm_size, upper_arm_offset_left, common_rotation);
        CreateRagdollBone(boneNodes[BONE_R_UPPERARM], SHAPE_CAPSULE, upper_arm_size, upper_arm_offset_right, common_rotation);

        CreateRagdollBone(boneNodes[BONE_L_FOREARM], SHAPE_CAPSULE, lower_arm_size, lower_arm_offset_left, common_rotation);
        CreateRagdollBone(boneNodes[BONE_R_FOREARM], SHAPE_CAPSULE, lower_arm_size, lower_arm_offset_right, common_rotation);

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

        Print("CreateRagdoll time-cost=" + (time.systemTime - t) + " ms");
    }

    void CreateRagdollBone(Node@ boneNode, ShapeType type, const Vector3&in size, const Vector3&in position, const Quaternion&in rotation)
    {
        RigidBody@ body = boneNode.CreateComponent("RigidBody");
        // Set mass to make movable
        body.mass = 1.0f;
        // Set damping parameters to smooth out the motion
        body.linearDamping = 0.075f;
        body.angularDamping = 0.85f;
        // Set rest thresholds to ensure the ragdoll rigid bodies come to rest to not consume CPU endlessly
        body.linearRestThreshold = 2.5f;
        body.angularRestThreshold = 1.5;
        body.collisionLayer = COLLISION_LAYER_RAGDOLL;
        body.collisionMask = COLLISION_LAYER_RAGDOLL | COLLISION_LAYER_PROP | COLLISION_LAYER_LANDSCAPE;
        body.friction = 0.75f;

        CollisionShape@ shape = boneNode.CreateComponent("CollisionShape");
        // We use either a box or a capsule shape for all of the bones
        if (type == SHAPE_BOX)
            shape.SetBox(size * scale, position * scale, rotation);
        else if (type == SHAPE_SPHERE)
            shape.SetSphere(size.x * scale, position * scale, rotation);
        else
            shape.SetCapsule(size.x * scale, size.y * scale, position * scale, rotation);
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
        for (uint i=0; i<boneNodes.length; ++i)
        {
            boneNodes[i].RemoveComponent("RigidBody");
            boneNodes[i].RemoveComponent("Constraint");
        }
    }

    void EnableRagdoll(bool bEnable)
    {
        for (uint i=0; i<boneNodes.length; ++i)
        {
            RigidBody@ rb = boneNodes[i].GetComponent("RigidBody");
            Constraint@ cs = boneNodes[i].GetComponent("Constraint");
            if (rb !is null)
                rb.enabled = bEnable;
            if (cs !is null)
                cs.enabled = bEnable;
        }
    }

    void FixedUpdate(float dt)
    {
        if (state == RAGDOLL_STATIC) {
            timeInState += dt;
        }
        else if (state == RAGDOLL_DYNAMIC) {
            int num_of_freeze_objects = 0;
            for (uint i=0; i<boneNodes.length; ++i)
            {
                // Vector3 curPos = boneNodes[i].worldPosition;
                RigidBody@ rb = boneNodes[i].GetComponent("RigidBody");
                if (rb is null || !rb.active) {
                    num_of_freeze_objects ++;
                    continue;
                }

                Vector3 vel = rb.linearVelocity;
                if (vel.lengthSquared < 0.01f)
                    num_of_freeze_objects ++;
                //Print(boneNodes[i].name + " vel=" + vel.ToString());
            }

            // Print("num_of_freeze_objects=" + num_of_freeze_objects);

            if (num_of_freeze_objects == boneNodes.length)
                ChangeState(RAGDOLL_NONE);
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
    }

    void HandleAnimationTrigger(StringHash eventType, VariantMap& eventData)
    {
        StringHash data = eventData[DATA].GetStringHash();
        int new_state = RAGDOLL_NONE;
        if (data == RAGDOLL_PERPARE)
            new_state = RAGDOLL_STATIC;
        else if (data == RAGDOLL_START)
            new_state = RAGDOLL_DYNAMIC;
        else if (data == RAGDOLL_STOP)
            new_state = RAGDOLL_NONE;
        ChangeState(new_state);
    }
}