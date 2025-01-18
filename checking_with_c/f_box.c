#include <stdio.h>
#include <stdlib.h>

// Ορισμός του τύπου BYTE (αντιστοιχεί σε unsigned char)
typedef unsigned char BYTE;

// Σταθερές για τον βαθμό και τον γεννήτορα του σώματος F_16
#define DEG_GF_POLY 4
#define GF_POLY 0x13 // x^4 + x + 1 -> δυαδική αναπαράσταση: 10011

BYTE gm(BYTE a, BYTE b) {
    BYTE g = 0;
    int i;
    for (i = 0; i < DEG_GF_POLY; i++) {
        if ( (b & 0x1) == 1 ) { g ^= a; }
        BYTE hbs = (a & 0x8);
        a <<= 0x1;
        if ( hbs == 0x8) { a ^= GF_POLY; }
        b >>= 0x1;
    }
    return g;
}

void print_binary(BYTE num) {
    for (int i = 3; i >= 0; i--) {
        printf("%d", (num >> i) & 1);
    }
}


int main(int argc, char *argv[]) {
    BYTE SBox[16] = {
        0xE, 0x4, 0xB, 0x2, 0x3, 0x8, 0x0, 0x9,
        0x1, 0xA, 0x7, 0xF, 0x6, 0xC, 0x5, 0xD
    };

    BYTE x[4] = {0xC, 0x2, 0x3, 0x5}; // Παράδειγμα τιμών για x σε δυαδική μορφή
    BYTE M[4][4] = {                              // Παράδειγμα πίνακα M (4x4) σε δυαδική μορφή
        {0x2, 0x3, 0x1, 0x1},
        {0x1, 0x2, 0x3, 0x1},
        {0x1, 0x1, 0x2, 0x3},
        {0x3, 0x1, 0x1, 0x2}
    };
    BYTE s[4];
    BYTE t[4]; // Αποθήκευση αποτελεσμάτων
    BYTE f[4];

    s[0] = SBox[x[0]];
    s[1] = SBox[x[1]];
    s[2] = SBox[x[2]];
    s[3] = SBox[x[3]];

    //s[0] = x[0];
    //s[1] = x[1];
    //s[2] = x[2];
    //s[3] = x[3];
    // Υπολογισμός των y[0] έως y[3] βάσει της συνάρτησης gm
    t[0] = (gm(s[0], M[0][0]) ^ gm(s[1], M[0][1]) ^ gm(s[2], M[0][2]) ^ gm(s[3], M[0][3]));
    t[1] = (gm(s[0], M[1][0]) ^ gm(s[1], M[1][1]) ^ gm(s[2], M[1][2]) ^ gm(s[3], M[1][3]));
    t[2] = (gm(s[0], M[2][0]) ^ gm(s[1], M[2][1]) ^ gm(s[2], M[2][2]) ^ gm(s[3], M[2][3]));
    t[3] = (gm(s[0], M[3][0]) ^ gm(s[1], M[3][1]) ^ gm(s[2], M[3][2]) ^ gm(s[3], M[3][3]));

    f[0] = SBox[t[0]];
    f[1] = SBox[t[1]];
    f[2] = SBox[t[2]];
    f[3] = SBox[t[3]];

    // Εκτύπωση αποτελεσμάτων
    printf("Results in binary:\n");
    //print_binary(gm(s[0], M[0][0]));
    printf("\n");
    for (int i = 0; i < 4; i++) {
        printf("s[%d] = ", i);
        print_binary(s[i]);
        printf("\n");
    }
    printf("\n");
    for (int i = 0; i < 4; i++) {
        printf("t[%d] = ", i);
        print_binary(t[i]);
        printf("\n");
     }
    printf("\n");
    for (int i = 0; i < 4; i++) {
        printf("f[%d] = ", i);
        print_binary(f[i]);
        printf("\n");
     }


    return 0;
}
