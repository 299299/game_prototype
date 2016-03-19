
class Line
{
    Vector3         start;
    Vector3         end;
    int             type;
};

class LineWorld
{
    Array<Line@>            lines;
    Array<Color>            debugColors;

    LineWorld()
    {

    }

    void DebugDraw(DebugRenderer@ debug)
    {
        for (uint i=0; i<lines.length; ++i)
        {
            Line@ l = lines[i];
            debug.AddLine(l.start, l.end, debugColors[l.type], false);
        }
    }
};