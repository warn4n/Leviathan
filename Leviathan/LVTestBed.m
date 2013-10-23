//
//  LVTestBed.m
//  Leviathan
//
//  Created by Steven on 10/19/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import "LVTestBed.h"

#include "lexer.h"






//#include "bstrlib.h"







//#include "token.h"
//#include "lexer.h"
//#include "atom.h"
//#include "parser.h"
//
//using namespace Leviathan;
//
//static void LVLexerShouldError(std::string raw, ParserError::Type error, NSRange badRange) {
//    std::pair<std::vector<Token*>, ParserError> result = lex(raw);
//    std::vector<Token*> tokens = result.first;
//    ParserError e = result.second;
//    if (e.type == ParserError::NoError) {
//        std::cout << "Didn't see expected error: " << raw << std::endl;
////        std::cout << tokens << std::endl;
//        exit(1);
//    }
//    else {
//        if (e.type != error) {
//            std::cout << raw << std::endl;
////            std::cout << tokens << std::endl;
//            printf("expected parser error to be %d, got %d\n", error, e.type);
//            exit(1);
//        }
//        if (!NSEqualRanges(badRange, NSMakeRange(e.pos, e.len))) {
////            std::cout << tokens << std::endl;
//            NSLog(@"thought: %@, got: %@", NSStringFromRange(badRange), NSStringFromRange(NSMakeRange(e.pos, e.len)));
//            exit(1);
//        }
//    }
//}

struct LVTokenList {
    LVToken** toks;
    size_t size;
};

static void LVLexerShouldEqual(char* raw, struct LVTokenList expected) {
    NSLog(@"%ld", expected.size);
    
    size_t actual_size;
    LVToken** tokens = LVLex(raw, &actual_size);
    
    if (actual_size != expected.size) {
        printf("wrong size: %s\n", raw);
        exit(1);
    }
    
    for (size_t i = 0; i < actual_size; i++) {
        LVToken* t1 = tokens[i];
        LVToken* t2 = expected.toks[i];
        
        if (t1->type != t2->type) {
            printf("wrong token type for: %s\n", raw);
            printf("want %llu, got %llu\n", t2->type, t1->type);
            exit(1);
        }
        
        if (bstrcmp(t1->val, t2->val) != 0) {
            printf("wrong token string for: %s\n", raw);
            printf("want %s, got %s\n", t2->val->data, t1->val->data);
            exit(1);
        }
    }
}

#define TOKARRAY(...) ((LVToken*[]){ __VA_ARGS__ })
#define TOKCOUNT(...) (sizeof(TOKARRAY(__VA_ARGS__)) / sizeof(LVToken*))
#define TOKLIST(...) ((struct LVTokenList){TOKARRAY(__VA_ARGS__), TOKCOUNT(__VA_ARGS__)})
#define TOK(typ, chr) LVTokenCreate(typ, chr, strlen(chr))

@implementation LVTestBed

+ (void) runTests {
    
    size_t tok_n;
    LVToken** tokens = LVLex("([:foo :bar]   :quux)", &tok_n);
    
    LVLexerShouldEqual("(foobar)", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_LParen, "("), TOK(LVTokenType_Symbol, "foobar"), TOK(LVTokenType_RParen, ")"), TOK(LVTokenType_FileEnd, "")));
    
    LVLexerShouldEqual("foobar", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_Symbol, "foobar"), TOK(LVTokenType_FileEnd, "")));
    LVLexerShouldEqual("(    foobar", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_LParen, "("), TOK(LVTokenType_Spaces, "    "), TOK(LVTokenType_Symbol, "foobar"), TOK(LVTokenType_FileEnd, "")));
    
    LVLexerShouldEqual("~", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_Unquote, "~"), TOK(LVTokenType_FileEnd, "")));
    LVLexerShouldEqual("~@", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_Splice, "~@"), TOK(LVTokenType_FileEnd, "")));
    
    LVLexerShouldEqual("\"yes\"", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_String, "\"yes\""), TOK(LVTokenType_FileEnd, "")));
    LVLexerShouldEqual("\"y\\\"es\"", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_String, "\"y\\\"es\""), TOK(LVTokenType_FileEnd, "")));
    
    LVLexerShouldEqual(";foobar\nhello", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_CommentLiteral, ";foobar"), TOK(LVTokenType_Newline, "\n"), TOK(LVTokenType_Symbol, "hello"), TOK(LVTokenType_FileEnd, "")));
    
    LVLexerShouldEqual("foo 123 :hello", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_Symbol, "foo"), TOK(LVTokenType_Spaces, " "), TOK(LVTokenType_Number, "123"), TOK(LVTokenType_Spaces, " "), TOK(LVTokenType_Keyword, ":hello"), TOK(LVTokenType_FileEnd, "")));
    
    LVLexerShouldEqual("#'foo", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_Var, "#'foo"), TOK(LVTokenType_FileEnd, "")));
    LVLexerShouldEqual("#(foo)", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_AnonFnStart, "#("), TOK(LVTokenType_Symbol, "foo"), TOK(LVTokenType_RParen, ")"), TOK(LVTokenType_FileEnd, "")));
    LVLexerShouldEqual("#{foo)", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_SetStart, "#{"), TOK(LVTokenType_Symbol, "foo"), TOK(LVTokenType_RBrace, ")"), TOK(LVTokenType_FileEnd, "")));
    LVLexerShouldEqual("#_foo", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_ReaderCommentStart, "#_"), TOK(LVTokenType_Symbol, "foo"), TOK(LVTokenType_FileEnd, "")));
    LVLexerShouldEqual("#foo bar", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_ReaderMacro, "#foo"), TOK(LVTokenType_Spaces, " "), TOK(LVTokenType_Symbol, "bar"), TOK(LVTokenType_FileEnd, "")));
    
    LVLexerShouldEqual("#\"yes\"", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_Regex, "#\"yes\""), TOK(LVTokenType_FileEnd, "")));
    LVLexerShouldEqual("#\"y\\\"es\"", TOKLIST(TOK(LVTokenType_FileBegin, ""), TOK(LVTokenType_Regex, "#\"y\\\"es\""), TOK(LVTokenType_FileEnd, "")));
    
//    // bad test, delete me:
////    LVLexerShouldEqual(";fo obar\nhello", {{token::Comment, ";foobar"}, {token::Newline, "\n"}, {token::Symbol, "hello"}});
//    
//    {
//        std::pair<Coll*, ParserError> result = parse("foo");
//        assert(result.second.type == ParserError::NoError);
//        assert(result.first->collType == Coll::TopLevel);
//        delete result.first;
//    }
//    
//    {
//        std::pair<Coll*, ParserError> result = parse("(foo");
//        assert(result.second.type == ParserError::UnclosedColl);
//    }
//    
//    {
//        std::pair<Coll*, ParserError> result = parse("(foo)");
//        assert(result.second.type == ParserError::NoError);
//        assert(result.first->collType == Coll::TopLevel);
//        delete result.first;
//    }
//    
//    {
//        std::pair<Coll*, ParserError> result = parse("((baryes)foo((no)))");
//        assert(result.second.type == ParserError::NoError);
//        assert(result.first->collType == Coll::TopLevel);
//        delete result.first;
//    }
//    
//    {
//        std::pair<Coll*, ParserError> result = parse("((bar yes) foo ((no)))");
//        assert(result.second.type == ParserError::NoError);
//        assert(result.first->collType == Coll::TopLevel);
//        delete result.first;
//    }
//    
//    {
//        std::pair<Coll*, ParserError> result = parse("123");
//        assert(result.second.type == ParserError::NoError);
//        assert(result.first->collType == Coll::TopLevel);
//        delete result.first;
//    }
//    
//    {
//        std::pair<Coll*, ParserError> result = parse(":bla");
//        assert(result.second.type == ParserError::NoError);
//        assert(result.first->collType == Coll::TopLevel);
//        delete result.first;
//    }
//    
//    {
//        std::pair<Coll*, ParserError> result = parse("[foo]");
//        assert(result.second.type == ParserError::NoError);
//        assert(result.first->collType == Coll::TopLevel);
//        delete result.first;
//    }
//    
//    {
//        std::pair<Coll*, ParserError> result = parse("{foo bar}");
//        assert(result.second.type == ParserError::NoError);
//        assert(result.first->collType == Coll::TopLevel);
//        delete result.first;
//    }
//    
//    {
//        std::pair<Coll*, ParserError> result = parse("#(foo bar)");
//        assert(result.second.type == ParserError::NoError);
//        assert(result.first->collType == Coll::TopLevel);
//        delete result.first;
//    }
//    
//    {
//        std::pair<Coll*, ParserError> result = parse(")");
//        assert(result.second.type == ParserError::UnopenedCollClosed);
//    }
    
    printf("ok\n");
    [NSApp terminate:self];
}

@end
