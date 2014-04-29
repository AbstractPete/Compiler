package com.kadet.compiler.evaluators;

import com.kadet.compiler.entities.Function;
import com.kadet.compiler.entities.Type;
import com.kadet.compiler.entities.Variable;

import java.util.List;

/**
 * Date: 30.03.14
 * Time: 13:18
 *
 * @author Кадет
 */
public class FunctionEvaluator extends ProcedureEvaluator{

    private Type returnType;

    public FunctionEvaluator (Function function) {
        super(function);
    }

    @Override
    public void evaluate () {
        super.evaluate();    //To change body of overridden methods use File | Settings | File Templates.
    }
}
