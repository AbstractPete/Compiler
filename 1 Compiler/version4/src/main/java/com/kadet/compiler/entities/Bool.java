package com.kadet.compiler.entities;

import com.kadet.compiler.Type;

/**
 * Date: 31.03.14
 * Time: 0:28
 *
 * @author Кадет
 */
public class Bool extends Element {

    public Bool (java.lang.Boolean bool) {
        super(bool);
        this.type = Type.BOOLEAN;
    }
}
