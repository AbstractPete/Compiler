grammar kadet;

options {

    // java lexer and parser
    language = Java;

    // abstract syntax tree
    output = AST;

}

@lexer::header {
    package com.kadet.compiler;
    import com.kadet.compiler.evaluators.*;
    import com.kadet.compiler.expressions.*;
    import com.kadet.compiler.entities.*;
    import com.kadet.compiler.util.*;
}

@parser::header {
    package com.kadet.compiler;
    import com.kadet.compiler.evaluators.*;
    import com.kadet.compiler.expressions.*;
    import com.kadet.compiler.entities.*;
    import com.kadet.compiler.util.*;
}

@members
{
    Program program = Program.getInstance();
}

program returns [ProgramEvaluator evaluator]
    :   'program' id = ID '='           {
                                            program.setProgramName($id.text);
                                            Procedure mainProcedure = new Procedure();
                                            program.setCurrentProcedure(mainProcedure);
                                            $evaluator = new ProgramEvaluator();
                                        }
        (
            variable                    {   mainProcedure.addVariables($variable.variables); }
            | constant                  {   mainProcedure.addConstants($constant.constants); }
            | procedure                 {
                                            mainProcedure.addProcedure($procedure.procedure);
                                            $procedure.procedure.setParentProcedure(mainProcedure);
                                        }
            | function                  {
                                            mainProcedure.addFunction($function.function);
                                            $function.function.setParentProcedure(mainProcedure);
                                        }
        )*
        'begin'                         {
                                            ProcedureEvaluator mainEvaluator = new ProcedureEvaluator(mainProcedure);
                                            $evaluator.setMainEvaluator(mainEvaluator);
                                        }
        (
            statement                   {   mainProcedure.addStatementEvaluator($statement.evaluator); }
        )*
        'end' ID '.'
    ;

constant returns [List<Constant> constants]
    :   'constant' id = ID                     {
                                                 $constants = new ArrayList<Constant>();
                                                 Constant constant = new Constant($id.text);
                                                 $constants.add(constant);
                                               }
       (
           ',' otherId = ID                    {
                                                 constant = new Constant($otherId.text);
                                                 $constants.add(constant);
                                               }
        )*
       ':='
            expression                         {
                                                  for (Constant currentConstant : $constants) {
                                                    currentConstant.setExpression($expression.expression);
                                                  }
                                               }
       ';'
    ;

variable returns [List<Variable> variables]
    :   'var' id = ID                           {
                                                  $variables = new ArrayList<Variable>();
                                                  Variable variable = new Variable($id.text);
                                                  $variables.add(variable);
                                                }
        (
            ',' otherId = ID                    {
                                                  variable = new Variable($otherId.text);
                                                  $variables.add(variable);
                                                }
         )*
        ':' type                                {
                                                  for (Variable var : $variables) {
                                                    var.setValue(ValueFactory.createValue($type.TYPE));
                                                  }
                                                }
        //(
        //':=' expression
        //)?
        ';'
    ;

type returns [Type TYPE]
    :   'List'                  { $TYPE = Type.LIST; }
    |   'Element'               { $TYPE = Type.ELEMENT; }
    |   'Integer'               { $TYPE = Type.INTEGER; }
    |   'Boolean'               { $TYPE = Type.BOOLEAN; }
    ;

statement returns [StatementEvaluator evaluator]
    :   assignmentStatement         { $evaluator = $assignmentStatement.evaluator; }
    |   ifStatement                 { $evaluator = $ifStatement.evaluator; }
    |   whileStatement              { $evaluator = $whileStatement.evaluator; }
    |   forStatement                { $evaluator = $forStatement.evaluator; }
    |   procedureCallStatement      { $evaluator = $procedureCallStatement.evaluator; }
    |   kadOutStatement             { $evaluator = $kadOutStatement.evaluator; }
    ;

ifStatement returns [IfEvaluator evaluator]
@init {

    $evaluator = new IfEvaluator();
    Choice ifChoice = null;
    java.util.List<Choice> elsIfChoices = new java.util.ArrayList<Choice>();
    Choice elsIfChoice = null;
    Choice elseChoice = null;

}
    :   'if' ifExpr = expression                { ifChoice = new Choice($ifExpr.expression); }
         'then'
            (
                ifStat = statement              { ifChoice.addStatementEvaluator($ifStat.evaluator); }
            )+
         (
        'elsif' elsIfExpr = expression          { elsIfChoice = new Choice($elsIfExpr.expression); }
         'then'
            (
                elsIfStat = statement           { elsIfChoice.addStatementEvaluator($elsIfStat.evaluator); }
            )+
                                                { elsIfChoices.add(elsIfChoice); }
         )*
        ('else'                                 { elseChoice = new Choice(); }
          'then'
            (
                elseStat = statement            { elseChoice.addStatementEvaluator($elseStat.evaluator); }
            )+
        )?
        'end' 'if' ';'                          {
                                                    $evaluator.setIfChoice(ifChoice);
                                                    $evaluator.setElsIfChoices(elsIfChoices);
                                                    $evaluator.setElseChoice(elseChoice);
                                                }
    ;

whileStatement returns [WhileEvaluator evaluator]
@init {
    $evaluator = new WhileEvaluator();
    Choice whileChoice = null;
}
    :   'while' expression                      { whileChoice = new Choice($expression.expression); }
        'begin'
            (
                statement                       { whileChoice.addStatementEvaluator($statement.evaluator); }
            )*
        'end' 'while' ';'                       {
                                                    $evaluator.setWhileChoice(whileChoice);
                                                }
    ;

forStatement returns [ForEvaluator evaluator]
@init {
    $evaluator = new ForEvaluator();
    Choice forChoice = null;
}
    :   'for'
        '('
            op1 = assignment                    { $evaluator.setInitializeCounterEvaluator($op1.evaluator); }
            ';'
            expression                          { forChoice = new Choice($expression.expression); }
            ';'
            op2 = assignment                    { $evaluator.setIncreaseCounterEvaluator($op2.evaluator); }
        ')'
        'begin'
            (
                statement                       { forChoice.addStatementEvaluator($statement.evaluator); }
            )*
        'end' 'for' ';'                         { $evaluator.setForChoice(forChoice); }
    ;

assignmentStatement returns [AssignmentEvaluator evaluator]
    :   assignment ';'              { $evaluator = $assignment.evaluator; }
    ;

assignment returns [AssignmentEvaluator evaluator]
    :	id = ID ':=' expression     { $evaluator = new AssignmentEvaluator($id.text, $expression.expression); }
    ;

//  expressions

term returns [Expression expression]
    :   element                                 { $expression = $element.expression; }
    |   list                                    { $expression = $list.expression; }
    |   '(' innerExpression = expression ')'    { $expression = $innerExpression.expression; }
    |   id = ID                                 { $expression = new ConstantOrVariableValueExpression($ID.text); }
    |   ID '[' innerExpr = expression ']'       { $expression = new ElementFromListExpression($ID.text, $innerExpr.expression); }
    |   'f:' ID '(' actualParameters ')'        { $expression = new FunctionCallExpression($ID.text, $actualParameters.expressions); }
    |   '>=>'                                    { $expression = new KadInExpression(System.in); }
    ;

element returns [Expression expression]
    :   INTEGER                                 { $expression = new ValueExpression(new Int(Integer.parseInt($INTEGER.text))); }
    |   '@true'                                 { $expression = new ValueExpression(new Bool(Boolean.parseBoolean("true"))); }
    |   '@false'                                { $expression = new ValueExpression(new Bool(Boolean.parseBoolean("false"))); }
    ;


list returns [Expression expression]
@init {
    java.util.List<Expression> expressions = new java.util.ArrayList<Expression>();
}
    :   '<'
        ( expression1 = expression              { expressions.add($expression1.expression); }

          (
          ',' expression2 = expression          { expressions.add($expression2.expression); }
          )*
        )? '>'                                  {
                                                  $expression = new ListExpression(expressions);
                                                }
    ;


// <1, 2> * 1 = < <1, 2>, 1 >
overList returns [Expression expression]
    :	expression1 = term                  { $expression = $expression1.expression; }
        (
        '*' expression2 = term              { $expression = new OverListExpression($expression, $expression2.expression); }
        )*
    ;

//  <1, 1, 2, 1> / 1 = <2>
removeAllElementEntries returns [Expression expression]
    :	expression1 = overList                  { $expression = $expression1.expression; }
        (
        '/' expression2 = overList              { $expression = new RemoveAllElementEntriesExpression($expression, $expression2.expression); }
        )*
    ;


//  <1, 1, 2, 1> - 1 = <1, 2, 1>
removeFromList returns [Expression expression]
    :	expression1 = removeAllElementEntries                    { $expression = $expression1.expression; }
        (
        '-' expression2 = removeAllElementEntries                { $expression = new RemoveFromListExpression($expression, $expression2.expression); }
        )*
    ;

// 1 + 2 = <1, 2>
// 1 + <1, 2> = <1, 1, 2>
// <1, 2> + 1 = <1, 2, 1>
// <1, 2> + <1, 3> = <1, 2, 1, 3>
addToList returns [Expression expression]
    :	expression1 = removeFromList                { $expression = $expression1.expression; }
        (
        '+' expression2 = removeFromList            { $expression = new AddToListExpression($expression, $expression2.expression); }
        )*
    ;

// 2 multiple 3 = 6
// 6 multiple 3 = 2
multiple returns [Expression expression]
    :   expression1 = addToList                     { $expression = $expression1.expression; }
        (
        'multiply' expression2 = addToList          { $expression = new MultipleExpression($expression, $expression2.expression); }
        | 'divide' expression2 = addToList          { $expression = new DivideExpression($expression, $expression2.expression); }
        )*
    ;

// 2 plus 3 = 5
// 3 minus 2 = 1
add returns [Expression expression]
    :   expression1 = multiple                      { $expression = $expression1.expression; }
        (
        'plus' expression2 = multiple               { $expression = new PlusExpression($expression, $expression2.expression); }
        | 'minus' expression2 = multiple            { $expression = new MinusExpression($expression, $expression2.expression); }
        )*
    ;


relation returns [Expression expression]
    :   expression1 = add                           { $expression = $expression1.expression; }
        (
        'equal'    expression2 = add                { $expression = new EqualExpression($expression, $expression2.expression); }
        | 'notEqual'  expression2 = add            { $expression = new NotEqualExpression($expression, $expression2.expression); }
        | 'lessOrEqual'   expression2 = add         { $expression = new LessOrEqualExpression($expression, $expression2.expression); }
        | 'less'   expression2 = add                { $expression = new LessExpression($expression, $expression2.expression); }
        | 'greater'   expression2 = add             { $expression = new GreaterExpression($expression, $expression2.expression); }
        | 'greaterOrEqual' expression2 = add   { $expression = new GreaterOrEqualExpression($expression, $expression2.expression); }
        )*
    ;


expression returns [Expression expression]
    :   expression1 = relation               { $expression = $expression1.expression; }
        (
        'and' expression2 = relation         { $expression = new AndExpression($expression, $expression2.expression); }
        | 'or' expression2 = relation        { $expression = new OrExpression($expression, $expression2.expression); }
        )*
    ;

procedure returns [Procedure procedure]
    :   'procedure' id = ID                  { $procedure = new Procedure($id.text); }
        '('
            parameters?                      {
                                                if ($parameters.parameters != null) {
                                                  $procedure.setParameters($parameters.parameters);
                                                }
                                             }
        ')' '='
        (
            constant                         { $procedure.addConstants($constant.constants); }
            | variable                       { $procedure.addVariables($variable.variables); }
            | innerProcedure = procedure     {
                                               $procedure.addProcedure($innerProcedure.procedure);
                                               $innerProcedure.procedure.setParentProcedure($procedure);
                                             }
            | innerFunction = function       {
                                               $procedure.addFunction($innerFunction.function);
                                               $innerFunction.function.setParentProcedure($procedure);
                                             }
        )*
        'begin'
        (
            statement                        { $procedure.addStatementEvaluator($statement.evaluator); }
        )*
        'end' ID '.'
    ;

procedureCallStatement returns [ProcedureCallEvaluator evaluator]
    :   id = ID '(' actualParameters ')' ';'    { $evaluator = new ProcedureCallEvaluator($id.text, $actualParameters.expressions); }
    ;

kadOutStatement returns [KadOutEvaluator evaluator]
@init {
    $evaluator = new KadOutEvaluator();
}
    :   '<=<'
        expr1 = expression          { $evaluator.addExpression($expr1.expression); }
        (','
            expr2 = expression      { $evaluator.addExpression($expr2.expression); }
        )*
        ';'
    ;

actualParameters returns [List<Expression> expressions]
@init {
    $expressions = new ArrayList<Expression>();
}
    :   (
            expr1 = expression          { $expressions.add($expr1.expression); }
            (','
                expr2 = expression      { $expressions.add($expr2.expression); }
            )*
        )?
    ;

function returns [Function function]
    :   'function' id = ID                   { $function = new Function($id.text); }
        '('
            parameters?                      {
                                               if ($parameters.parameters != null) {
                                                 $function.setParameters($parameters.parameters);
                                               }
                                             }
        ')'
        '='
        (
            constant                         { $function.addConstants($constant.constants); }
            | variable                       { $function.addVariables($variable.variables); }
            | innerProcedure = procedure     {
                                               $function.addProcedure($innerProcedure.procedure);
                                               $innerProcedure.procedure.setParentProcedure($function);
                                             }
            | innerFunction = function       {
                                               $function.addFunction($innerFunction.function);
                                               $innerFunction.function.setParentProcedure($function);
                                             }
        )*
        'begin'
        (
            statement                        { $function.addStatementEvaluator($statement.evaluator); }
            | returnStatement                { $function.addStatementEvaluator($returnStatement.evaluator); }
        )*
        'end' ID '.'
    ;

returnStatement returns [StatementEvaluator evaluator]
    :   'return' expression ';'              { $evaluator = new ReturnStatementEvaluator($expression.expression); }
    ;

parameters returns [List<ProcedureParameter> parameters]
@init {
    $parameters = new ArrayList<ProcedureParameter>();
}
    :   parameter1 = parameter              { $parameters.add($parameter1.parameter); }
        (
            ','
            parameter2 = parameter          { $parameters.add($parameter2.parameter); }
        )*
    ;

parameter returns [ProcedureParameter parameter]
    :   ID ':' type                         { $parameter = new ProcedureParameter($ID.text, $type.TYPE); }
    ;

fragment LETTER
    :   ('a'..'z' | 'A'..'Z')
    ;

fragment DIGIT
    :   '0'..'9'
    ;

ID
    :   ( LETTER )( LETTER | DIGIT )*
    ;

INTEGER
    :   DIGIT+
    ;

STRING_LITERAL
    :   '"'
                                        {
                                            StringBuilder b = new StringBuilder();
                                        }
        (
        ('\\' '"')                      {   b.appendCodePoint('"');}
        |
        c = ~( '"' | '\r' | '\n' )      {   b.appendCodePoint(c);}
        )*
        '"'
                                        {   setText (b.toString());}
    ;

CHAR_LITERAL
    :   '\'' . '\'' {setText(getText().substring(1, 2));}
    ;

WS
    :   (' ' | '\t' | '\n' | '\r' | '\f')+  {$channel = HIDDEN;}
    ;

COMMENT
    :   '//' .* ('\n' | '\r')   {$channel = HIDDEN;}
    ;

MULTIPLE_COMMENT
    :   '/*' .* '*/'    {$channel = HIDDEN;}
    ;