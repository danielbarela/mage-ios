//
//  SessionTaskQueue.m
//  mage-ios-sdk
//
//  Created by Brian Osborn on 2/14/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "SessionTaskQueue.h"
#import "AFURLSessionManager.h"

/**
 * Active running session task information
 */
@interface ActiveSessionTask: NSObject

/**
 * Originating session task
 */
@property (nonatomic, strong) SessionTask *sessionTask;

/**
 * Active url session task
 */
@property (nonatomic, strong) NSURLSessionTask *task;

/**
 * Task start time
 */
@property (nonatomic, strong) NSDate *startTime;

@end

@implementation ActiveSessionTask
@end

@interface SessionTaskQueue()

/**
 * Dictionary of active url session task identifiers and the active session task
 */
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, ActiveSessionTask *> *activeTasks;

/**
 * Dictionary of session task identifiers and current number of active tasks allocated to the session task
 */
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *activePerSessionTask;

/**
 * Task queue of tasks to process sorted by priority
 */
@property (nonatomic, strong) NSMutableOrderedSet<SessionTask *> *taskQueue;

/**
 * Task queue count of tasks, including embedded tasks
 */
@property (nonatomic) int taskQueueCount;

/**
 * Flag indicating a requested stop
 */
@property (nonatomic) BOOL stop;

@end

@implementation SessionTaskQueue

static int defaultMaxConcurrentTasks = 4;

-(instancetype) init{
    return [self initWithMaxConcurrentTasks:defaultMaxConcurrentTasks];
}

-(instancetype) initWithMaxConcurrentTasks: (int) maxConcurrentTasks{
    self = [super init];
    if(self){
        _maxConcurrentTasks = maxConcurrentTasks;
        _activeTasks = [[NSMutableDictionary alloc] init];
        _activePerSessionTask = [[NSMutableDictionary alloc] init];
        _taskQueue = [[NSMutableOrderedSet alloc] init];
        _taskQueueCount = 0;
        _stop = NO;
        
        NSLog(@"%@ Init, Max Concurrent Tasks: %d", NSStringFromClass([self class]), _maxConcurrentTasks);
        
        // Observe task notifications
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(networkRequestDidFinish:) name:AFNetworkingTaskDidSuspendNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(networkRequestDidFinish:) name:AFNetworkingTaskDidCompleteNotification object:nil];
    }
    return self;
}

-(void) close{
        
    @synchronized (self) {
            
        _stop = YES;
        
        [self removeObservers];
            
        [_taskQueue removeAllObjects];
        _taskQueueCount = 0;
        [_activePerSessionTask removeAllObjects];
        
        for(ActiveSessionTask *activeTask in _activeTasks){
            NSURLSessionTask *runTask = activeTask.task;
            [runTask cancel];
        }
        [_activeTasks removeAllObjects];
            
    }
    
}

-(void) finishAndClose{
    
    @synchronized (self) {
        
        _stop = YES;
        
        [self closeIfFinished];
    }
    
}

-(void) closeIfFinished{
    
    if(_stop && _taskQueue.count == 0 && _activeTasks.count == 0){
        [self removeObservers];
    }
    
}

-(void) addTask: (NSURLSessionTask *) task{
    
    if (![task isKindOfClass:[NSURLSessionTask class]]){
        [NSException raise:@"Unexpected Task Type" format:@"Task must be a subtype of %@", NSStringFromClass([NSURLSessionTask class])];
    }
    
    [self addSessionTask:[[SessionTask alloc] initWithTask:task]];
}

-(void) addSessionTask: (SessionTask *) task{
    
    if (![task isKindOfClass:[SessionTask class]]){
        [NSException raise:@"Unexpected Task Type" format:@"Task must be a subtype of %@", NSStringFromClass([SessionTask class])];
    }
    
    [self verifyActive];
    
    @synchronized (self) {
        
        [self verifyActive];
        
        // Insert the task in priority order
        NSUInteger insertLocation = [_taskQueue indexOfObject:task inSortedRange:NSMakeRange(0, _taskQueue.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(SessionTask * obj1, SessionTask * obj2){
            NSComparisonResult result = NSOrderedAscending;
            if(obj2.priority > obj1.priority){
                result = NSOrderedDescending;
            }
            return result;
        }];
        [_taskQueue insertObject:task atIndex:insertLocation];
        _taskQueueCount += [task remainingTasks];
        
        // Start the next task if active space available
        if(![self startNextTask]){
            [self logStatus];
        }
    }
}

/**
 * Remove the task observers
 */
-(void) removeObservers{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AFNetworkingTaskDidSuspendNotification object:nil];
    [notificationCenter removeObserver:self name:AFNetworkingTaskDidCompleteNotification object:nil];
}

/**
 * Verify the queue is still active, raise an exception if closed
 */
-(void) verifyActive{
    if(_stop){
        [NSException raise:@"Session Task Manager Closed" format:@"The Session Task Manager has been closed and can not accept new tasks"];
    }
}

/**
 * Start the next task if a task is queued and active space is available
 *
 * @return YES if a task was started
 */
-(BOOL) startNextTask{
    
    BOOL started = NO;
    
    // Is there a task queues and is active space
    if(_taskQueue.count > 0 && _activeTasks.count < _maxConcurrentTasks){

        SessionTask *sessionTask = nil;
        int taskIndex;
        NSNumber *activeFromTask = nil;
        
        // Find the next task in the queue that does not have max active task allocation provided to it
        for(taskIndex = 0; taskIndex < _taskQueue.count; taskIndex++){
            SessionTask *tempTask = [_taskQueue objectAtIndex:taskIndex];
            activeFromTask = [_activePerSessionTask objectForKey:[tempTask taskIdentifier]];
            if(activeFromTask == nil){
                activeFromTask = [NSNumber numberWithInt:0];
            }
            if([activeFromTask intValue] < tempTask.maxConcurrentTasks){
                sessionTask = tempTask;
                break;
            }
        }
        
        if(sessionTask != nil){
            // Start the task
            NSURLSessionTask *runTask = [sessionTask removeTask];
            NSDate * startTime = [NSDate date];
            [runTask resume];
            
            ActiveSessionTask *activeTask = [[ActiveSessionTask alloc] init];
            [activeTask setSessionTask:sessionTask];
            [activeTask setTask:runTask];
            [activeTask setStartTime:startTime];
            
            [_activeTasks setObject:activeTask forKey:[NSNumber numberWithUnsignedInteger:runTask.taskIdentifier]];
            [_activePerSessionTask setObject:[NSNumber numberWithInt:[activeFromTask intValue] + 1] forKey:[sessionTask taskIdentifier]];
            
            // One task in the queue was added to active
            _taskQueueCount--;
            
            // If all tasks from the sesion task have been started, remove from the task queue
            if(![sessionTask hasTask]){
                [_taskQueue removeObjectAtIndex:taskIndex];
            }
            
            started = YES;
            [self logStatus];
            
            // Check if another task should be started
            [self startNextTask];
        }
    }
    
    return started;
}

-(void) logStatus{
    NSLog(@"%@ Status, Active Tasks: %d, Task Queue: %d", NSStringFromClass([self class]),(int)_activeTasks.count, (int)_taskQueueCount);
}

/**
 * Task finished observer. Free active task space and start the next.
 * 
 * @param notification   task finished notification
 */
- (void)networkRequestDidFinish:(NSNotification *)notification {
    
    NSDate * endTime = [NSDate date];
    NSNumber *taskIdentifier = [self taskIdentifierOfNotification:notification];
    
    // Check if this task was started by this queue
    ActiveSessionTask *activeTask = [_activeTasks objectForKey:taskIdentifier];
    if(activeTask != nil){
    
        @synchronized (self) {
            
            // Remove from active tasks
            [_activeTasks removeObjectForKey:taskIdentifier];
            
            // Update active tasks per session task count
            SessionTask *sessionTask = activeTask.sessionTask;
            NSString *sessionTaskIdentifier = [sessionTask taskIdentifier];
            if([sessionTask hasTask]){
                NSNumber *activeFromTask = [_activePerSessionTask objectForKey:sessionTaskIdentifier];
                if(activeFromTask != nil && [activeFromTask intValue] > 0){
                    [_activePerSessionTask setObject:[NSNumber numberWithInt:[activeFromTask intValue] - 1] forKey:sessionTaskIdentifier];
                }
            }else{
                [_activePerSessionTask removeObjectForKey:sessionTaskIdentifier];
            }
            
            // Log request url and execution time
            NSURLRequest *request = activeTask.task.originalRequest;
            NSString * requestUrl = [[request URL] absoluteString];
            NSTimeInterval seconds = [endTime timeIntervalSinceDate:activeTask.startTime];
            NSLog(@"%@ Timer, Request: %@, Seconds: %f", NSStringFromClass([self class]), requestUrl, seconds);
            
            // Start the next task
            if(![self startNextTask]){
                [self logStatus];
            }
            
            // Close the queue if stopped and finished
            [self closeIfFinished];
        }
    }
    
}

/**
 * Get the task identifier from the notification
 *
 * @param notification   task notification
 * @return task identifier
 */
-(NSNumber *) taskIdentifierOfNotification: (NSNotification *) notification{
    NSURLSessionTask *task = notification.object;
    NSUInteger taskIdentifier = task.taskIdentifier;
    return [NSNumber numberWithUnsignedInteger:taskIdentifier];
}


@end
