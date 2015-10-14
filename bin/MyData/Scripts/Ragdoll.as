// CreateRagdoll script object class
class Ragdoll : ScriptObject
{
    void Start()
    {
        // Subscribe physics collisions that concern this scene node
        // SubscribeToEvent(node, "NodeCollision", "HandleNodeCollision");
        CreateRagdoll();
    }

    void HandleNodeCollision(StringHash eventType, VariantMap& eventData)
    {
        // Get the other colliding body, make sure it is moving (has nonzero mass)
        RigidBody@ otherBody = eventData["OtherBody"].GetPtr();

        if (otherBody.mass > 0.0f)
        {
            // We do not need the physics components in the AnimatedModel's root scene node anymore
            node.RemoveComponent("RigidBody");
            node.RemoveComponent("CollisionShape");


            CreateRagdoll();
            // Finally remove self (the ScriptInstance which holds this script object) from the scene node. Note that this must
            // be the last operation performed in the function
            self.Remove();
        }
    }

    void CreateRagdoll()
    {
        // Create RigidBody & CollisionShape components to bones
        CreateRagdollBone("Bip01_Head", SHAPE_BOX, Vector3(0.25f, 0.2f, 0.2f), Vector3(0.0f, 0.0f, 0.0f), Quaternion(0.0f, 0.0f, 0.0f));
        CreateRagdollBone("Bip01_Pelvis", SHAPE_BOX, Vector3(0.3f, 0.2f, 0.25f), Vector3(0.0f, 0.0f, 0.0f), Quaternion(0.0f, 0.0f, 0.0f));
        CreateRagdollBone("Bip01_Spine1", SHAPE_BOX, Vector3(0.35f, 0.2f, 0.3f), Vector3(0.15f, 0.0f, 0.0f), Quaternion(0.0f, 0.0f, 0.0f));
        float upper_arm_radius = 0.125f + 0.025f;
        float lower_arm_radius = 0.15f + 0.025f;
        float uppper_leg_radius = 0.175f + 0.025f;
        float lower_leg_radius = 0.15f + 0.025f;

        CreateRagdollBone("Bip01_L_Thigh", SHAPE_CAPSULE, Vector3(uppper_leg_radius, 0.45f, uppper_leg_radius), Vector3(0.25f, 0.0f, 0.0f), Quaternion(0.0f, 0.0f, 90.0f));
        CreateRagdollBone("Bip01_R_Thigh", SHAPE_CAPSULE, Vector3(uppper_leg_radius, 0.45f, uppper_leg_radius), Vector3(0.25f, 0.0f, 0.0f), Quaternion(0.0f, 0.0f, 90.0f));
        CreateRagdollBone("Bip01_L_Calf", SHAPE_CAPSULE, Vector3(lower_leg_radius, 0.55f, lower_leg_radius), Vector3(0.25f, 0.0f, 0.0f), Quaternion(0.0f, 0.0f, 90.0f));
        CreateRagdollBone("Bip01_R_Calf", SHAPE_CAPSULE, Vector3(lower_leg_radius, 0.55f, lower_leg_radius), Vector3(0.25f, 0.0f, 0.0f), Quaternion(0.0f, 0.0f, 90.0f));
        CreateRagdollBone("Bip01_L_UpperArm", SHAPE_CAPSULE, Vector3(upper_arm_radius, 0.35f, upper_arm_radius), Vector3(0.1f, 0.0f, 0.0f), Quaternion(0.0f, 0.0f, 90.0f));
        CreateRagdollBone("Bip01_R_UpperArm", SHAPE_CAPSULE, Vector3(upper_arm_radius, 0.35f, upper_arm_radius), Vector3(0.1f, 0.0f, 0.0f), Quaternion(0.0f, 0.0f, 90.0f));
        CreateRagdollBone("Bip01_L_Forearm", SHAPE_CAPSULE, Vector3(lower_arm_radius, 0.4f, lower_arm_radius), Vector3(0.2f, 0.0f, 0.0f), Quaternion(0.0f, 0.0f, 90.0f));
        CreateRagdollBone("Bip01_R_Forearm", SHAPE_CAPSULE, Vector3(lower_arm_radius, 0.4f, lower_arm_radius), Vector3(0.2f, 0.0f, 0.0f), Quaternion(0.0f, 0.0f, 90.0f));

        // Create Constraints between bones
        CreateRagdollConstraint("Bip01_Head", "Bip01_Spine1", CONSTRAINT_CONETWIST, Vector3(-1.0f, 0.0f, 0.0f), Vector3(-1.0f, 0.0f, 0.0f), Vector2(0.0f, 30.0f), Vector2(0.0f, 0.0f));

        CreateRagdollConstraint("Bip01_L_Thigh", "Bip01_Pelvis", CONSTRAINT_CONETWIST, Vector3(0.0f, 0.0f, -1.0f),
            Vector3(0.0f, 0.0f, 1.0f), Vector2(45.0f, 45.0f), Vector2(0.0f, 0.0f));
        CreateRagdollConstraint("Bip01_R_Thigh", "Bip01_Pelvis", CONSTRAINT_CONETWIST, Vector3(0.0f, 0.0f, -1.0f),
            Vector3(0.0f, 0.0f, 1.0f), Vector2(45.0f, 45.0f), Vector2(0.0f, 0.0f));
        CreateRagdollConstraint("Bip01_L_Calf", "Bip01_L_Thigh", CONSTRAINT_HINGE, Vector3(0.0f, 0.0f, -1.0f),
            Vector3(0.0f, 0.0f, -1.0f), Vector2(90.0f, 0.0f), Vector2(0.0f, 0.0f));
        CreateRagdollConstraint("Bip01_R_Calf", "Bip01_R_Thigh", CONSTRAINT_HINGE, Vector3(0.0f, 0.0f, -1.0f),
            Vector3(0.0f, 0.0f, -1.0f), Vector2(90.0f, 0.0f), Vector2(0.0f, 0.0f));
        CreateRagdollConstraint("Bip01_Spine1", "Bip01_Pelvis", CONSTRAINT_HINGE, Vector3(0.0f, 0.0f, 1.0f),
            Vector3(0.0f, 0.0f, 1.0f), Vector2(45.0f, 0.0f), Vector2(-10.0f, 0.0f));
        CreateRagdollConstraint("Bip01_L_UpperArm", "Bip01_Spine1", CONSTRAINT_CONETWIST, Vector3(0.0f, -1.0f, 0.0f),
            Vector3(0.0f, 1.0f, 0.0f), Vector2(45.0f, 45.0f), Vector2(0.0f, 0.0f), false);
        CreateRagdollConstraint("Bip01_R_UpperArm", "Bip01_Spine1", CONSTRAINT_CONETWIST, Vector3(0.0f, -1.0f, 0.0f),
            Vector3(0.0f, 1.0f, 0.0f), Vector2(45.0f, 45.0f), Vector2(0.0f, 0.0f), false);
        CreateRagdollConstraint("Bip01_L_Forearm", "Bip01_L_UpperArm", CONSTRAINT_HINGE, Vector3(0.0f, 0.0f, -1.0f),
            Vector3(0.0f, 0.0f, -1.0f), Vector2(90.0f, 0.0f), Vector2(0.0f, 0.0f));
        CreateRagdollConstraint("Bip01_R_Forearm", "Bip01_R_UpperArm", CONSTRAINT_HINGE, Vector3(0.0f, 0.0f, -1.0f),
            Vector3(0.0f, 0.0f, -1.0f), Vector2(90.0f, 0.0f), Vector2(0.0f, 0.0f));

        // Disable keyframe animation from all bones so that they will not interfere with the ragdoll
        AnimatedModel@ model = node.children[0].GetComponent("AnimatedModel");
        Skeleton@ skeleton = model.skeleton;
        for (uint i = 0; i < skeleton.numBones; ++i)
            skeleton.bones[i].animated = false;
    }

    void CreateRagdollBone(const String&in boneName, ShapeType type, const Vector3&in size, const Vector3&in position, const Quaternion&in rotation)
    {
        // Find the correct child scene node recursively
        Node@ boneNode = node.GetChild(boneName, true);
        if (boneNode is null)
        {
            log.Warning("Could not find bone " + boneName + " for creating ragdoll physics components");
            return;
        }

        const float scale = 100.0f;

        RigidBody@ body = boneNode.CreateComponent("RigidBody");
        // Set mass to make movable
        body.mass = 1.0f;
        // Set damping parameters to smooth out the motion
        body.linearDamping = 0.05f;
        body.angularDamping = 0.85f;
        // Set rest thresholds to ensure the ragdoll rigid bodies come to rest to not consume CPU endlessly
        body.linearRestThreshold = 1.5f;
        body.angularRestThreshold = 2.5f;

        CollisionShape@ shape = boneNode.CreateComponent("CollisionShape");
        // We use either a box or a capsule shape for all of the bones
        if (type == SHAPE_BOX)
            shape.SetBox(size * scale, position * scale, rotation);
        else if (type == SHAPE_SPHERE)
            shape.SetSphere(size.x * scale, position * scale, rotation);
        else
            shape.SetCapsule(size.x * scale, size.y * scale, position * scale, rotation);
    }

    void CreateRagdollConstraint(const String&in boneName, const String&in parentName, ConstraintType type,
        const Vector3&in axis, const Vector3&in parentAxis, const Vector2&in highLimit, const Vector2&in lowLimit,
        bool disableCollision = true)
    {
        Node@ boneNode = node.GetChild(boneName, true);
        Node@ parentNode = node.GetChild(parentName, true);
        if (boneNode is null)
        {
            log.Warning("Could not find bone " + boneName + " for creating ragdoll constraint");
            return;
        }
        if (parentNode is null)
        {
            log.Warning("Could not find bone " + parentName + " for creating ragdoll constraint");
            return;
        }

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
}