//
//  MessagesVC.m
//  Whatsapp
//
//  Created by Gui David
//  Adapted from Rafael Castro
//


// Cells
#import "MessageCell.h"

// View controllers
#import "MessagesVC.h"
#import "EditMessageVC.h"
#import "MarkdownExportVC.h"

// Util
#import "Util.h"

// Helpers
#import "Inputbar.h"
#import "DAKeyboardControl.h"

@interface MessagesVC() <InputbarDelegate,
                                    UITableViewDataSource, UITableViewDelegate, ContainerProtocol>

@property (weak, nonatomic) IBOutlet Inputbar *inputbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *markdownButton;

@end

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation MessagesVC

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self setInputbar];
    [self setTableView];
    //[self setGateway];
    [self.tableView registerClass:MessageCell.class forCellReuseIdentifier:@"MessageCell"];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    __weak Inputbar *inputbar = _inputbar;
    __weak UITableView *tableView = _tableView;
    __weak MessagesVC *controller = self;
    
    self.view.keyboardTriggerOffset = inputbar.frame.size.height;
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
        /*
         Try not to call "self" inside this block (retain cycle).
         But if you do, make sure to remove DAKeyboardControl
         when you are done with the view controller by calling:
         [self.view removeKeyboardControl];
         */
        
        CGRect toolBarFrame = inputbar.frame;
        toolBarFrame.origin.y = keyboardFrameInView.origin.y - toolBarFrame.size.height;
        inputbar.frame = toolBarFrame;
        
        CGRect tableViewFrame = tableView.frame;
        tableViewFrame.size.height = toolBarFrame.origin.y - 64;
        tableView.frame = tableViewFrame;
        
        [controller tableViewScrollToBottomAnimated:NO];
    }];
}


-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.view endEditing:YES];
    [self.view removeKeyboardControl];
    //[self.gateway dismiss];
}

#pragma mark -

-(void)setInputbar {
    self.inputbar.placeholder = @"";
    self.inputbar.delegate = self;
    self.inputbar.rightButtonText = @"Send";
    self.inputbar.rightButtonTextColor = [UIColor colorWithRed:0 green:124/255.0 blue:1 alpha:1];
}

-(void) setTableView {
    //self.tableArray = [[TableArray alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f,self.view.frame.size.width, 10.0f)];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor]; //UIColorFromRGB(0xDFDBC4);//
    [self.tableView registerClass:[MessageCell class] forCellReuseIdentifier: @"MessageCell"];
}

/*
-(void)setGateway
{
    self.gateway = [MessageGateway sharedInstance];
    self.gateway.delegate = self;
    self.gateway.chat = self.chat;
    [self.gateway loadOldMessages];
}
*/

- (void) setChat:(Chat *)chat {
    _chat = chat;
    self.title = chat.recipientName;
}

#pragma mark - Actions

- (IBAction)userDidTapScreen:(id)sender {
    [_inputbar resignFirstResponder];
}

#pragma mark - TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chat.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"MessageCell";
    MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[MessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.message = self.chat.messages[indexPath.row];
    cell.delegate = self;
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = self.chat.messages[indexPath.row];
    return message.height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"test";
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGRect frame = CGRectMake(0, 0, tableView.frame.size.width, 40);
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = [UIColor clearColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"Helvetica" size:20.0];
    [label sizeToFit];
    label.center = view.center;
    label.font = [UIFont fontWithName:@"Helvetica" size:13.0];
    label.backgroundColor = [UIColor colorWithRed:207/255.0 green:220/255.0 blue:252.0/255.0 alpha:1];
    label.layer.cornerRadius = 10;
    label.layer.masksToBounds = YES;
    label.autoresizingMask = UIViewAutoresizingNone;
    [view addSubview:label];
    
    return view;
}


- (void)tableViewScrollToBottomAnimated:(BOOL)animated {
    NSInteger numberOfRows = self.chat.messages.count;
    
    // Open chat in the very last message
    if (numberOfRows) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(self.chat.messages.count - 1) inSection:0];
        
        [_tableView scrollToRowAtIndexPath:indexPath
                    atScrollPosition:UITableViewScrollPositionBottom
                    animated:animated];
    }
}

#pragma mark - InputbarDelegate

-(void)inputbarDidPressRightButton:(Inputbar *)inputbar {
    Message *message = [[Message alloc] init];
    message.text = [Util removeEndSpaceFrom:inputbar.text];
    //inputbar.text;
    message.chatId = _chat.objectId;
    
    //Store Message in memory
    [self.chat.messages addObject:message];
    
    //Insert Message in UI
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.chat.messages.count - 1 inSection:0];
    
    [self.tableView beginUpdates];
    
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
    
    [self.tableView endUpdates];
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.chat.messages.count-1 inSection:0]
                    atScrollPosition:UITableViewScrollPositionBottom
                    animated:YES];
    
    //Send message to server
    //[self.gateway sendMessage:message];
}

-(void)inputbarDidChangeHeight:(CGFloat)new_height {
    //Update DAKeyboardControl
    self.view.keyboardTriggerOffset = new_height;
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
   if ([segue.identifier isEqualToString:@"EditMessageSegue"]) {
        EditMessageVC *editMessageVC = [segue destinationViewController];
        Message *messageToPass = sender;
        editMessageVC.message = messageToPass;
        editMessageVC.delegate = self;
    }
   else if ([segue.identifier isEqualToString:@"MarkdownSegue"]) {
       MarkdownExportVC *markdownExportVC = [segue destinationViewController];
       Chat *chat = sender;
       markdownExportVC.chat = chat;
   }
}

#pragma mark - Container methods

- (void)editMessage:(Message *)message {
    [self performSegueWithIdentifier:@"EditMessageSegue" sender:message];
}

- (void)deleteMessage:(Message *)message {
    // Update array
    NSMutableArray<Message *> *chatMessages = self.chat.messages;
    NSInteger messageIndex = [chatMessages indexOfObject:message];
    [chatMessages removeObjectAtIndex:messageIndex];
    
    NSArray *indexPaths = [[NSArray alloc]
                           initWithObjects:[NSIndexPath indexPathForRow:messageIndex inSection:0], nil];
    
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    return;
}

- (void)changeSender:(Message *)message {
    // Gets the message cell based on the index of the array
    NSInteger messageIndex = [_chat.messages indexOfObject:message];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messageIndex inSection:0];
    NSArray *indexPaths = [[NSArray alloc]
                           initWithObjects:indexPath, nil];
    
    // Change the data model only. (reload will cause the cell to reload)
    message.sender = message.sender == MessageSenderMyself? MessageSenderSomeone: MessageSenderMyself;
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    return;
}

- (IBAction)didPressMarkdown:(id)sender {
    [self performSegueWithIdentifier:@"MarkdownSegue" sender:self.chat];
    return;
}

@end