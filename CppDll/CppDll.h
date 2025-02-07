#pragma once


extern "C" __declspec(dllexport) void __cdecl CppScharrFunction(
    const unsigned char* inputImage,  
    unsigned char* outputImage, 
    int width,                   
    int height
);