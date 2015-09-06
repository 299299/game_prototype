#include "Scripts/Test/FSM.as"

const int CTRL_ATTACK = (1 << 0);
const int CTRL_JUMP = (1 << 1);
const int CTRL_ALL = (1 << 16);

class GameObject : ScriptObject
{
    FSM@ stateMachine;
    bool onGround;
    bool isSliding;
    float duration;

    GameObject()
    {
        onGround = false;
        isSliding = false;
        duration = -1; // Infinite
        @stateMachine = FSM();
    }

    void Stop()
    {
        @stateMachine = null;
    }

    void FixedUpdate(float timeStep)
    {
        // Disappear when duration expired
        if (duration >= 0)
        {
            duration -= timeStep;
            if (duration <= 0)
                node.Remove();
        }
    }

    void Update(float timeStep)
    {
        stateMachine.Update(timeStep);
    }

    void PlaySound(const String&in soundName)
    {
        // Create the sound channel
        SoundSource3D@ source = node.CreateComponent("SoundSource3D");
        Sound@ sound = cache.GetResource("Sound", soundName);

        source.SetDistanceAttenuation(2, 50, 1);
        source.Play(sound);
        source.autoRemove = true;
    }

    void HandleNodeCollision(StringHash eventType, VariantMap& eventData)
    {
        Node@ otherNode = eventData["OtherNode"].GetPtr();
        RigidBody@ otherBody = eventData["OtherBody"].GetPtr();

        // If the other collision shape belongs to static geometry, perform world collision
        if (otherBody.collisionLayer == 2)
            WorldCollision(eventData);

        // If the other node is scripted, perform object-to-object collision
        GameObject@ otherObject = cast<GameObject>(otherNode.scriptObject);
        if (otherObject !is null)
            ObjectCollision(otherObject, eventData);
    }

    void WorldCollision(VariantMap& eventData)
    {
        VectorBuffer contacts = eventData["Contacts"].GetBuffer();
        while (!contacts.eof)
        {
            Vector3 contactPosition = contacts.ReadVector3();
            Vector3 contactNormal = contacts.ReadVector3();
            float contactDistance = contacts.ReadFloat();
            float contactImpulse = contacts.ReadFloat();

            // If contact is below node center and mostly vertical, assume it's ground contact
            if (contactPosition.y < node.position.y)
            {
                float level = Abs(contactNormal.y);
                if (level > 0.75)
                    onGround = true;
                else
                {
                    // If contact is somewhere inbetween vertical/horizontal, is sliding a slope
                    if (level > 0.1)
                        isSliding = true;
                }
            }
        }

        // Ground contact has priority over sliding contact
        if (onGround == true)
            isSliding = false;
    }

    void ObjectCollision(GameObject@ otherObject, VariantMap& eventData)
    {
    }

    void ResetWorldCollision()
    {
        RigidBody@ body = node.GetComponent("RigidBody");
        if (body.active)
        {
            onGround = false;
            isSliding = false;
        }
        else
        {
            // If body is not active, assume it rests on the ground
            onGround = true;
            isSliding = false;
        }
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        stateMachine.DebugDraw(debug);
    }

    String GetDebugText()
    {
        return stateMachine.GetDebugText();
    }
};
