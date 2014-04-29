package com.kadet.compiler.util;

import com.kadet.compiler.entities.Constant;
import com.kadet.compiler.entities.Variable;

import java.util.ArrayList;
import java.util.List;

/**
 * Date: 01.04.14
 * Time: 12:30
 *
 * @author Кадет
 */
public final class VariableUtils {

    public static void copyVariableList (List<Variable> variables) {
        List<Variable> copyVariables = new ArrayList<Variable>();
        for (Variable variable : variables) {
            copyVariables.add(variable.copy());
        }
    }

    public static boolean hasSuchVariableOrConstantName (String name, List<Variable> variables, List<Constant> constants) {
        boolean hasName = false;
        for (Variable variable : variables) {
            if (variable.hasSuchName(name)) {
                hasName = true;
            }
        }
        for (Constant constant : constants) {
            if (constant.hasSuchName(name)) {
                hasName = true;
            }
        }
        return hasName;
    }

    public static boolean hasSuchVariableName (String name, List<Variable> variables) {
        boolean hasName = false;
        for (Variable variable : variables) {
            if (variable.hasSuchName(name)) {
                hasName = true;
            }
        }
        return hasName;
    }


/*

    public static List<Variable> addOrUpdateVariablesInList (List<Variable> newVariables, List<Variable> list) {
        for (Variable variable : newVariables) {
            boolean isNew = true;
            for (Variable variable) {

            }
        }
    }
*/
}
