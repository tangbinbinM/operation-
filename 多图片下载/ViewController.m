//
//  ViewController.m
//  多图片下载
//
//  Created by YiGuo on 2017/10/26.
//  Copyright © 2017年 tbb. All rights reserved.
//

#import "ViewController.h"
#import "TBBAppModel.h"
@interface ViewController ()
//获取数据
@property (nonatomic,copy)NSArray *apps;
//内存缓存图片
@property (nonatomic,strong)NSMutableDictionary *imageCache;
//存队列任务，防止重复下载
@property (nonatomic,strong)NSMutableDictionary *operations;
//多线程队列
@property (nonatomic,strong)NSOperationQueue *queue;

@end

@implementation ViewController
- (NSOperationQueue *)queue
{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 3;
    }
    return _queue;
}
- (NSMutableDictionary *)operations
{
    if (!_operations) {
        _operations = [NSMutableDictionary dictionary];
    }
    return _operations;
}
- (NSMutableDictionary *)imageCache
{
    if (!_imageCache) {
        _imageCache = [NSMutableDictionary dictionary];
    }
    return _imageCache;
}
- (NSArray *)apps
{
    if (!_apps) {
        NSArray *dictArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"apps.plist" ofType:nil]];
        NSMutableArray *appArray = [NSMutableArray array];
        for (NSDictionary *dict in dictArray) {
            [appArray addObject:[TBBAppModel appWithDict:dict]];
        }
        _apps = appArray;
    }
    return _apps;
}
- (void)viewDidLoad {
    [super viewDidLoad];

}

#pragma mark -- Delegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.apps.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *ID = @"app";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    TBBAppModel *appModel = self.apps[indexPath.row];
    cell.textLabel.text = appModel.name;
    cell.detailTextLabel.text = appModel.download;
    
    //先从内存的缓存中取
    UIImage *image = self.imageCache[appModel.icon];
    if (image) {
        cell.imageView.image = image;
    }else{
        //内存的缓存中没有图片
        // 获得Library/Caches文件夹
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        //获得文件名称
        NSString *filename = [appModel.icon lastPathComponent];
        // 计算出文件的全路径
        NSString *file = [cachesPath stringByAppendingPathComponent:filename];
        //加载沙盒的文件数据[NSData dataWithContentsOfFile:file]
        NSData *data = [NSData dataWithContentsOfFile:file];
        
        if (data) {
            //从沙盒中取的数据
            cell.imageView.image = [UIImage imageWithData:data];
            //存入字典
            self.imageCache[appModel.icon] = cell.imageView.image;
        }else{
            cell.imageView.image = [UIImage imageNamed:@"icn.jpg"];
            //多线程下载图片
            //问题1
            //当图片还没有下载完成时在出现的cell有继续创建队列
            /*
             缓存下载任务
             用于判断是否已存在下载任务
            **/
            //问题2
            //那行数据下载好就更新那一行数据
            
            NSOperation *operation = self.operations[appModel.icon];
            
            if (operation == nil) {
                //当前图片还没有下载任务
                operation = [NSBlockOperation blockOperationWithBlock:^{
                    //下载图片
                    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:appModel.icon]];
                    //数据加载失败
                    if (data == nil) {
                        //移除操作
                        [self.operations removeObjectForKey:appModel.icon];
                        return;
                    }
                    UIImage *image = [UIImage imageWithData:data];
                    //存入字典
                    self.imageCache[appModel.icon] = image;
                    //回到主线程显示图片
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        //那行下好更新那好
                        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    }];
                    //将图片文件写入沙盒
                    [data writeToFile:file atomically:YES];
                    //移除操作
                    [self.operations removeObjectForKey:appModel.icon];
                    
                }];
                
            }
            //添加进队列
            [self.queue addOperation:operation];
            self.operations[appModel.icon] = operation;
        }
    }
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}


@end
