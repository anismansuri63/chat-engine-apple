/**
 * @author Serhii Mamontov
 * @version 0.10.0
 * @copyright © 2010-2018 PubNub, Inc.
 */
#import "CENMe.h"
#import "CENChatEngine+EventEmitter.h"
#import "CENChatEngine+Private.h"
#import "CENObject+Private.h"
#import "CENChat+Interface.h"
#import "CENUser+Interface.h"
#import "CENUser+Private.h"
#import "CENErrorCodes.h"


NS_ASSUME_NONNULL_BEGIN

#pragma mark Protected interface declaration

@interface CENMe ()


#pragma mark - Connection

/**
 * @brief Perform sequental connection to \b {local user CENMe} private chats (\b {CENUser.direct}
 * and \b {CENUser.feed}).
 */
- (void)connectToPersonalChatsIfRequired;

#pragma mark -


@end

NS_ASSUME_NONNULL_END


#pragma mark - Interface implementation

@implementation CENMe


#pragma mark - Information

+ (NSString *)objectType {
    
    return CENObjectType.me;
}

- (CENSession *)session {
    
    return self.chatEngine.synchronizationSession;
}

- (CENMe * (^)(NSDictionary *state, CENChat *chat))update {
    
    return ^CENMe * (NSDictionary *state, CENChat *chat) {
        [self updateState:state forChat:chat];
        return self;
    };
}

#pragma mark - Initialization and Configuration

+ (instancetype)userWithUUID:(NSString *)uuid
                       state:(NSDictionary *)state
                  chatEngine:(CENChatEngine *)chatEngine {
    
    CENMe *me = (CENMe *)[super userWithUUID:uuid state:state chatEngine:chatEngine];
    [me connectToPersonalChatsIfRequired];
    
    return me;
}


#pragma mark - Connection

- (void)connectToPersonalChatsIfRequired {

    [self.direct handleEventOnce:@"$.connected"
                withHandlerBlock:^(CENEmittedEvent * __unused event) {
                    
        [self.feed connectChat];
    }];
    
    [self.direct connectChat];
}


#pragma mark - State

- (void)updateState:(NSDictionary *)state forChat:(CENChat *)chat {

    chat = chat ?: self.chatEngine.global;

    if (!chat) {
        NSString *description = @"No chat specified for state update.";
        NSError *error = [NSError errorWithDomain:kCENErrorDomain
                                             code:kCENChatMissingError
                                         userInfo:@{ NSLocalizedDescriptionKey : description }];

        [self.chatEngine throwError:error
                           forScope:@"updateParam"
                               from:self
                      propagateFlow:CEExceptionPropagationFlow.middleware];

        return;
    }

    [self assignState:state forChat:chat];
    [chat setState:[self stateForChat:chat]];
}


#pragma mark - Clean up

- (void)destruct {
    
    [super destruct];
}


#pragma mark - Misc

- (NSString *)description {
    
    return [NSString stringWithFormat:@"<CENMe:%p uuid: '%@'>", self, self.uuid];
}

#pragma mark -


@end
