package com.kadet.compiler.entities;

import com.kadet.compiler.Type;

/**
 * Date: 31.03.14
 * Time: 0:25
 *
 * @author Кадет
 */
public class Int extends Element{

    public Int (java.lang.Integer integer) {
        super(integer);
        this.type = Type.INTEGER;
    }
}
