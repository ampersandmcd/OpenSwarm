/*
 * Andrew McDonald
 * Michigan State University D-CYPHER Lab
 * Parser.h
 * 9.1.19
 * 
 * Provides functionality to decode 'turn and burst' commands of the form '<ROBOT_ID>angle,velocity</ROBOT_ID>' sent by the Matlab server.
 */

#include "Configuration.h"

#ifndef parser
#define parser

class Parser
{
private:
    Configuration &Config;

public:
    Parser(Configuration &config) : Config(config){};

    // Purpose:     Checks command string to see if it contains a command relevant to this robot
    // Params:      (String& command)   Reference string to command in question
    // Returns:     Boolean indicating presence of relevant command for this robot
    bool HasCommand(String &command)
    {
        if (command.indexOf("<" + String(Config.ID) + ">") != -1 && command.indexOf("<start>") != -1 && command.indexOf("<end>") != -1)
        {
            return true;
        }

        return false;
    }

    // Purpose:     Parses command string to obtain command relevant to this robot
    // Params:      (String& command)   Reference string to command in question
    //              (float ary[])       float array in which to store [angle, velocity]
    // Returns:     void; modifies ary[] param to contain [angle, velocity] for this robot
    void ParseCommand(String &command, float ary[])
    {
        String myCommand = "";
        int start = command.indexOf("<" + String(Config.ID) + ">") + 2 + String(Config.ID).length();
        int finish = command.indexOf("</" + String(Config.ID) + ">");
        myCommand = command.substring(start, finish);

        int angleStart = 0;
        int angleFinish = myCommand.indexOf(",", angleStart);
        String angleString = myCommand.substring(angleStart, angleFinish);
        float angle = angleString.toFloat();

        int velocityStart = angleFinish + 1;
        String velocityString = myCommand.substring(velocityStart);
        float velocity = velocityString.toFloat();

        ary[0] = angle;
        ary[1] = velocity;
    }
};

#endif