#include "pch.h"
#include "CppDll.h"
#include <cmath>
#include <algorithm>

static const int Gx[3][3] = {
    { 3,  0, -3 },
    { 10, 0, -10 },
    { 3,  0, -3 }
};

static const int Gy[3][3] = {
    { 3,  10,  3 },
    { 0,   0,  0 },
    { -3, -10, -3 }
};

extern "C" __declspec(dllexport) void __cdecl CppScharrFunction(const unsigned char* inputImage, unsigned char* outputImage, int width, int height){
    for (int x = 0; x < width; x++) {
        outputImage[x] = 0; // górny rz¹d
        outputImage[(height - 1) * width + x] = 0; // dolny rz¹d
    }
    for (int y = 0; y < height; y++) {
        outputImage[y * width] = 0; // lewy kolumna
        outputImage[y * width + (width - 1)] = 0; // prawy kolumna
    }

    // Przetwarzanie obrazu – pomijamy krawêdzie
    for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
            int sumX = 0;
            int sumY = 0;
            // Przechodzimy po oknie 3x3
            for (int j = -1; j <= 1; j++) {
                for (int i = -1; i <= 1; i++) {
                    int pixel = inputImage[(y + j) * width + (x + i)];
                    sumX += pixel * Gx[j + 1][i + 1];
                    sumY += pixel * Gy[j + 1][i + 1];
                }
            }
            // Obliczenie wartoœci gradientu – tutaj stosujemy przybli¿enie modu³u (mo¿na u¿yæ np. sqrt(sumX*sumX + sumY*sumY))
            int magnitude = abs(sumX) + abs(sumY);
            if (magnitude > 255)
                magnitude = 255;
            outputImage[y * width + x] = static_cast<unsigned char>(magnitude);
        }
    }
 
}



