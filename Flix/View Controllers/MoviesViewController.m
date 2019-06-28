//
//  MoviesViewController.m
//  Flix
//
//  Created by panzaldo on 6/26/19.
//  Copyright © 2019 panzaldo. All rights reserved.
//

#import "MoviesViewController.h"
#import "MovieCell.h"
#import "UIImageView+AFNetworking.h"
#import "DetailsViewController.h"

@interface MoviesViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *movies;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) NSArray *filteredData;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;


@end

@implementation MoviesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.searchBar.delegate = self;

    
    [self fetchMovies];

    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchMovies) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
}

- (void) fetchMovies {
    
    // Start the activity indicator
    [self.activityIndicator startAnimating];
    
    NSURL *url = [NSURL URLWithString:@"https://api.themoviedb.org/3/movie/now_playing?api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            
            //Displays message error if no WiFi Connection
            NSLog(@"%@", [error localizedDescription]);
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot get movies" message:@"The internet connection appears to be offline" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Try again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                //fectches movies, refreshes with WiFi
                [self viewDidLoad];
            }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:cancel];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];

            
        }
        else {
            // Stop the activity indicator
            // Hides automatically if "Hides When Stopped" is enabled
            
            [self.activityIndicator stopAnimating];
            
            NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            
            self.movies = dataDictionary[@"results"];
            self.filteredData = self.movies;
    
            
            [self.tableView reloadData];
        }
        
        [self.refreshControl endRefreshing];
        
    }];
    [task resume];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {

    if (searchText.length != 0) {
        NSString *searchString = [NSString stringWithString:searchText];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title contains[c] %@", searchString];
        self.filteredData = [self.movies filteredArrayUsingPredicate:predicate];
        NSLog(@"%@", self.filteredData);
    }
    else {
        self.filteredData = self.movies;
    }

    [self.tableView reloadData];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.filteredData.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    MovieCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MovieCell"];
    
    NSDictionary *movie = self.filteredData[indexPath.row];
    cell.titleLabel.text = movie[@"title"];
    cell.synposisLabel.text = movie[@"overview"];
    
    NSString *baseURLString = @"https:/image.tmdb.org/t/p/w500";
    NSString *posterURLString = movie[@"poster_path"];
    NSString *fullPosterURLString = [baseURLString stringByAppendingString:posterURLString];
    
    NSURL *posterURL = [NSURL URLWithString:fullPosterURLString];
    cell.posterView.image = nil;
    [cell.posterView setImageWithURL:posterURL];

    
    return cell;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    UITableViewCell *tappedCell = sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
    NSDictionary *movie = self.movies[indexPath.row];
    
    DetailsViewController *detailsViewController = [segue destinationViewController];
    
    detailsViewController.movie = movie;
    
}

@end
