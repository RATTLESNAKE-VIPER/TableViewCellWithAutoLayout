//
//  RJTableViewController.m
//  TableViewController
//
//  Created by Kevin Muldoon & Tyler Fox on 10/5/13.
//  Copyright (c) 2013 RobotJackalope. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "RJTableViewController.h"
#import "RJModel.h"
#import "RJTableViewCell.h"

static NSString *CellIdentifier = @"CellIdentifier";
static CGFloat kLineSpacing = 10.0f;

@interface RJTableViewController ()

@property (strong, nonatomic) RJModel *model;

// This property is used to work around the constraint exception that is thrown if the
// estimated row height for an inserted row is greater than the actual height for that row.
// See: https://github.com/caoimghgin/TableViewCellWithAutoLayout/issues/6
@property (assign, nonatomic) BOOL isInsertingRow;

@end

@implementation RJTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.title = @"Table View Controller";
        self.model = [[RJModel alloc] init];
        [self.model populateDataSource];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[RJTableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(clear:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addRow:)];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentSizeCategoryChanged:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIContentSizeCategoryDidChangeNotification
                                                  object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)contentSizeCategoryChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)clear:(id)sender
{
    NSMutableArray *rowsToDelete = [NSMutableArray new];
    for (NSUInteger i = 0; i < [self.model.dataSource count]; i++) {
        [rowsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    self.model = [[RJModel alloc] init];
    
    [self.tableView deleteRowsAtIndexPaths:rowsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.tableView reloadData];
}

- (void)addRow:(id)sender
{
    [self.model addSingleItemToDataSource];
    
    self.isInsertingRow = YES;
    
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:[self.model.dataSource count] - 1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[lastIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    self.isInsertingRow = NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.model.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RJTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [cell updateFonts];
    
    //
    // It is unfortunate making autoLayout work with UITableView/UITableCell requires a duplication of building of strings in
    // – tableView:heightForRowAtIndexPath: as well as method tableView:cellForRowAtIndexPath: So be aware if you see unexpected
    // behavior, check to see the building of titleText and bodyText is identical in both methods.
    //
    NSString *titleText = [self.model titleForIndex:indexPath.row];
    NSMutableAttributedString *titleAttributedText = [[NSMutableAttributedString alloc] initWithString:titleText];
    NSMutableParagraphStyle *titleParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [titleParagraphStyle setLineSpacing:3.0f];
    [titleAttributedText addAttribute:NSParagraphStyleAttributeName value:titleParagraphStyle range:NSMakeRange(0, titleText.length)];
    cell.titleLabel.attributedText = titleAttributedText; // Yes, darned silly to set leading of a single line textField but we aim for consistancy.
    
    NSString *bodyText = [self.model bodyForIndex:indexPath.row];
    NSMutableAttributedString *bodyAttributedText = [[NSMutableAttributedString alloc] initWithString:bodyText];
    NSMutableParagraphStyle *bodyParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [bodyParagraphStyle setLineSpacing:kLineSpacing];
    [bodyAttributedText addAttribute:NSParagraphStyleAttributeName value:bodyParagraphStyle range:NSMakeRange(0, bodyText.length)];
    cell.bodyLabel.attributedText = bodyAttributedText;
    
    cell.footnoteLabel.text = [self.model footnoteForIndex:indexPath.row];
    
    // No, you don't need to use an NSAttributedString, but it's helpful if you want to adjust leading (line spacing).
    // So if you simply want to use a regular string with default leading, comment out the text above and uncomment
    // the following code, keeping in mind you'll need to duplicate building of string in method tableView:heightForRowAtIndexPath:
    /*
     cell.bodyLabel.text = [self.model bodyForIndex:indexPath.row];
     cell.titleLabel.text = [self.model titleForIndex:indexPath.row];
     */
    
    // Make sure the constraints have been added to this cell, since it may have just been created from scratch
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    // Since we have multi-line labels, do an initial layout pass and then set the preferredMaxLayoutWidth
    // based on their width so they will wrap text and take on the correct height
    [cell.contentView setNeedsLayout];
    [cell.contentView layoutIfNeeded];
    cell.bodyLabel.preferredMaxLayoutWidth = CGRectGetWidth(cell.bodyLabel.frame);
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RJTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [cell updateFonts];
    
    //
    // It is unfortunate making autoLayout work with UITableView/UITableCell requires a duplication of building of strings in
    // – tableView:heightForRowAtIndexPath: as well as method tableView:cellForRowAtIndexPath: So be aware if you see unexpected
    // behavior, check to see the building of titleText and bodyText is identical in both methods.
    //
    NSString *titleText = [self.model titleForIndex:indexPath.row];
    NSMutableAttributedString *titleAttributedText = [[NSMutableAttributedString alloc] initWithString:titleText];
    NSMutableParagraphStyle *titleParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [titleParagraphStyle setLineSpacing:3.0f];
    [titleAttributedText addAttribute:NSParagraphStyleAttributeName value:titleParagraphStyle range:NSMakeRange(0, titleText.length)];
    cell.titleLabel.attributedText = titleAttributedText; // Yes, darned silly to set leading of a single line textField but we aim for consistancy.
    
    NSString *bodyText = [self.model bodyForIndex:indexPath.row];
    NSMutableAttributedString *bodyAttributedText = [[NSMutableAttributedString alloc] initWithString:bodyText];
    NSMutableParagraphStyle *bodyParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [bodyParagraphStyle setLineSpacing:kLineSpacing];
    [bodyAttributedText addAttribute:NSParagraphStyleAttributeName value:bodyParagraphStyle range:NSMakeRange(0, bodyText.length)];
    cell.bodyLabel.attributedText = bodyAttributedText;
    
    cell.footnoteLabel.text = [self.model footnoteForIndex:indexPath.row];

    
    // No, you don't need to use an NSAttributedString, but it's helpful if you want to adjust leading (line spacing).
    // So if you simply want to use a regular string with default leading, comment out the text above and uncomment
    // the following code, keeping in mind you'll need to duplicate building of string in method tableView:heightForRowAtIndexPath:
    /*
     cell.bodyLabel.text = [self.model bodyForIndex:indexPath.row];
     cell.titleLabel.text = [self.model titleForIndex:indexPath.row];
     */
    
    // Update Constraints here
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    // Do the initial layout pass of the cell's contentView & subviews
    [cell.contentView setNeedsLayout];
    [cell.contentView layoutIfNeeded];
    
    // Since we have multi-line labels, set the preferredMaxLayoutWidth now that their width has been determined,
    // and then do a second layout pass so they can take on the correct height
    cell.bodyLabel.preferredMaxLayoutWidth = CGRectGetWidth(cell.bodyLabel.frame);
    [cell.contentView layoutIfNeeded];
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isInsertingRow) {
        // A constraint exception will be thrown if the estimated row height for an inserted row is greater
        // than the actual height for that row. In order to work around this, we return the actual height
        // for the the row when inserting into the table view.
        // See: https://github.com/caoimghgin/TableViewCellWithAutoLayout/issues/6
        return [self tableView:tableView heightForRowAtIndexPath:indexPath];
    } else {
        return 500.0f;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //
    // I've notice a bug when rotating iOS device. Cells with multi-line labels will not compress when entering landscape mode
    // leaving a lot of extra white space at top and bottom of the cell.  Must circle back and correct this behavior. Suspect
    // this is happening in tableView:estimatedHeightForRowAtIndexPath which may need to be re-called programatically.
    //
    [self.tableView setNeedsUpdateConstraints];
    [self.tableView updateConstraintsIfNeeded];
}

@end
