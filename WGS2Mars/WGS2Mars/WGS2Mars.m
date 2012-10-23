//
//  WGS2Mars.m
//  WGS2Mars
//
//  Created by 谌启亮 on 12-10-23.
//  Copyright (c) 2012年 谌启亮. All rights reserved.
//

#import "WGS2Mars.h"

typedef struct offset_data {
    int16_t lng;    //12151表示121.51
    int16_t lat;    //3130表示31.30
    int16_t x_off;  //地图x轴偏移像素值
    int16_t y_off;  //地图y轴偏移像素值
}offset_data;

//GPS值转换像素值
static double lngToPixel(double lng, int zoom) {
    return (lng + 180) * (256L << zoom) / 360;
}
static double latToPixel(double lat, int zoom) {
    double siny =sin(lat * M_PI / 180);
    double y = log((1 + siny) / (1 - siny));
    return (128 << zoom) * (1 - y / (2 * M_PI));
}

//像素值转GPS值
static double pixelToLng(double pixelX, int zoom) {
    return pixelX * 360 / (256L << zoom) - 180;
}
static double pixelToLat(double pixelY, int zoom) {
    double y = 2 * M_PI * (1 - pixelY / (128 << zoom));
    double z = pow(M_E, y);
    double siny = (z - 1) / (z + 1);
    return asin(siny) * 180 / M_PI;
}


static int compare_offset_data(offset_data *data1, offset_data *data2){
    int det_lng = (data1->lng)-(data2->lng);
    if (det_lng!=0) {
        return det_lng;
    }
    else{
        return (data1->lat)-(data2->lat);
    }
}

//WGS标准GPS转火星坐标系
void WGS2Mars(double *lat, double *lng){
    //使用文件－内存映射减少大文件内存消耗
    NSData *offsetFileData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"offset" ofType:@"dat"] options:NSDataReadingMappedIfSafe error:NULL];
    const void *buf = [offsetFileData bytes]; //byte buf for content of file "offset.dat"
    long long buflen = [offsetFileData length]; //length of byte buf for content of file "offset.dat"
    offset_data search_data;
    search_data.lat = (int)(*lat*100);
    search_data.lng = (int)(*lng*100);
    offset_data *ret = bsearch(&search_data, buf, buflen/sizeof(offset_data), sizeof(offset_data), (int (*)(const void *, const void *))compare_offset_data);//折半查找
    double pixY = latToPixel(*lat, 18);
    double pixX = lngToPixel(*lng, 18);
    pixY += ret->y_off;
    pixX += ret->x_off;
    *lat = pixelToLat(pixY, 18);
    *lng = pixelToLng(pixX, 18);
}