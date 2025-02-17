#include <stdio.h>
#include <stdlib.h>
#define KEYSIZE       128 /* 80 or 128 */
#define RN            31 /* 25 or 31 */
#define N             16 /* 10 or 16 */

typedef unsigned char BYTE; /* 8 bit */
typedef unsigned long WORD; /* 32 bit */

/* key */
typedef struct {
  WORD wKey[2]; /* whitening keys: wKey[0] = w_0 | w_1, wKey[1] = w_2 | w_3 */
  WORD rKey[RN]; /* round keys: 2 round keys are encoded in a 32-bit word */
} KEY;

#if KEYSIZE==80
const WORD C[RN] = {
  0x071c293d, 0x1f1a253e, 0x1718213f, 0x2f163d38, 0x27143939,
  0x3f12353a, 0x3710313b, 0x4f0e0d34, 0x470c0935, 0x5f0a0536,
  0x57080137, 0x6f061d30, 0x67041931, 0x7f021532, 0x77001133,
  0x8f3e6d2c, 0x873c692d, 0x9f3a652e, 0x9738612f, 0xaf367d28,
  0xa7347929, 0xbf32752a, 0xb730712b, 0xcf2e4d24, 0xc72c4925
};
/* Input Key 80-bit*/
BYTE key[10] = {
            0xAA, 0xCD, 0xCA, 0xCA, 0xB2,
            0xB2, 0xBB, 0x55, 0x66, 0xAA
};
#elif KEYSIZE==128
const WORD C[RN] = {
  0x6d45ad8a, 0x7543a189, 0x7d41a588, 0x454fb98f, 0x4d4dbd8e,
  0x554bb18d, 0x5d49b58c, 0x25578983, 0x2d558d82, 0x35538181,
  0x3d518580, 0x055f9987, 0x0d5d9d86, 0x155b9185, 0x1d599584,
  0xe567e99b, 0xed65ed9a, 0xf563e199, 0xfd61e598, 0xc56ff99f,
  0xcd6dfd9e, 0xd56bf19d, 0xdd69f59c, 0xa577c993, 0xad75cd92,
  0xb573c191, 0xbd71c590, 0x857fd997, 0x8d7ddd96, 0x957bd195,
  0x9d79d594
};
/* Input Key 128-bit*/
BYTE key[16] = {
            0xAC, 0xAD, 0xB8, 0xCB,
            0xD6, 0xA9, 0x6F, 0x5C,
            0xCA, 0x9A, 0x5C, 0xB9,
            0x62, 0xA9, 0x6B, 0xCC
        };
#endif



void keySchedule(BYTE x[], KEY *k) {
//    if (KEYSIZE==80){
//        const WORD C[RN] = {
//          0x071c293d, 0x1f1a253e, 0x1718213f, 0x2f163d38, 0x27143939,
//          0x3f12353a, 0x3710313b, 0x4f0e0d34, 0x470c0935, 0x5f0a0536,
//          0x57080137, 0x6f061d30, 0x67041931, 0x7f021532, 0x77001133,
//          0x8f3e6d2c, 0x873c692d, 0x9f3a652e, 0x9738612f, 0xaf367d28,
//          0xa7347929, 0xbf32752a, 0xb730712b, 0xcf2e4d24, 0xc72c4925
//        };
//    } else if (KEYSIZE==128) {
//        const WORD C[RN] = {
//          0x6d45ad8a, 0x7543a189, 0x7d41a588, 0x454fb98f, 0x4d4dbd8e,
//          0x554bb18d, 0x5d49b58c, 0x25578983, 0x2d558d82, 0x35538181,
//          0x3d518580, 0x055f9987, 0x0d5d9d86, 0x155b9185, 0x1d599584,
//          0xe567e99b, 0xed65ed9a, 0xf563e199, 0xfd61e598, 0xc56ff99f,
//          0xcd6dfd9e, 0xd56bf19d, 0xdd69f59c, 0xa577c993, 0xad75cd92,
//          0xb573c191, 0xbd71c590, 0x857fd997, 0x8d7ddd96, 0x957bd195,
//          0x9d79d594
//        };
//    }

      /* init whitening keys */
      k->wKey[0] = 0x0;
      k->wKey[1] = 0x0;

      /* init round keys */
      int i;
      for (i = 0; i < RN; i++) {
        k->rKey[i] = 0x0;
      }

      /* compute keys */
      if (KEYSIZE == 80) {

        /* set whitening keys */
        k->wKey[0] ^= (x[0] << 24);
        k->wKey[0] ^= (x[3] << 16);
        k->wKey[0] ^= (x[2] <<  8);
        k->wKey[0] ^= (x[1] <<  0);

        k->wKey[1] ^= (x[8] << 24);
        k->wKey[1] ^= (x[7] << 16);
        k->wKey[1] ^= (x[6] <<  8);
        k->wKey[1] ^= (x[9] <<  0);


        /* set round keys */
        int r = 0;
        for (r = 0; r < RN; r++) {

          /* generates the constants */
          //k->rKey[r] ^= ((r+1) << 27) ^ ((r+1) << 17) ^ ((r+1) << 10) ^ ((r+1) << 0) ^ 0x0F1E2D3C;
          //printf("%08x\n", k->rKey[r]);

          /* use precomputed constants */
          k->rKey[r] ^= C[r];

          if ( r%5 == 0 || r%5 == 2 ) {
            k->rKey[r] ^= (x[4] << 24) ^ (x[5] << 16) ^ (x[6] << 8) ^ (x[7] << 0);
          } else if ( r%5 == 1 || r%5 == 4 ) {
            k->rKey[r] ^= (x[0] << 24) ^ (x[1] << 16) ^ (x[2] << 8) ^ (x[3] << 0);
          } else if (r%5 == 3) {
            k->rKey[r] ^= (x[8] << 24) ^ (x[9] << 16) ^ (x[8] << 8) ^ (x[9] << 0);
          }
        }

      } else if (KEYSIZE == 128) {

        /* set whitening keys */
        k->wKey[0] ^= (x[ 0] << 24);
        k->wKey[0] ^= (x[ 3] << 16);
        k->wKey[0] ^= (x[ 2] <<  8);
        k->wKey[0] ^= (x[ 1] <<  0);

        k->wKey[1] ^= (x[ 8] << 24);
        k->wKey[1] ^= (x[15] << 16);
        k->wKey[1] ^= (x[14] <<  8);
        k->wKey[1] ^= (x[ 9] <<  0);

        int r = 0;
        /* init buffer */
        BYTE y[N];
        for (r = 0; r < N; r++) {
          y[r] = x[r];
        }

        /* generates the constants
        for (r = 0; r < RN; r++) {
          k->rKey[r] ^= ((r+1) << 27) ^ ((r+1) << 17) ^ ((r+1) << 10) ^ ((r+1) << 0)  ^ 0x6547A98B;
          printf("%08x\n", k->rKey[r]);
        }
        */

        for (r = 0; r < 2*RN; r++) {
          int c = (r+2)%8;
          if (c == 0) {
            y[ 0] = x[ 4]; y[ 1] = x[ 5]; // k_0 = k_2
            y[ 2] = x[ 2]; y[ 3] = x[ 3]; // k_1 = k_1
            y[ 4] = x[12]; y[ 5] = x[13]; // k_2 = k_6
            y[ 6] = x[14]; y[ 7] = x[15]; // k_3 = k_7
            y[ 8] = x[ 0]; y[ 9] = x[ 1]; // k_4 = k_0
            y[10] = x[ 6]; y[11] = x[ 7]; // k_5 = k_3
            y[12] = x[ 8]; y[13] = x[ 9]; // k_6 = k_4
            y[14] = x[10]; y[15] = x[11]; // k_7 = k_5

            /* update x */
            int i = 0;
            for (i = 0; i < N; i++) {
              x[i] = y[i];
            }
          }
          if (r%2 == 0) {
            k->rKey[r/2] ^= (C[r/2] & 0xffff0000) ^ (y[2*c] << 24) ^ (y[2*c+1] << 16);
          } else {
            k->rKey[r/2] ^= (C[r/2] & 0x0000ffff) ^ (y[2*c] << 8) ^ (y[2*c+1] << 0);
          }
        }
      }
}

int main(int argc, char *argv[]) {

//    if (KEYSIZE == 80){
//        BYTE key[10] = {
//            0xAA, 0xCD, 0xCA, 0xCA, 0xB2,
//            0xB2, 0xBB, 0x55, 0x66, 0xAA
//        };
//    } else if (KEYSIZE == 128){
//        BYTE key[16] = {
//            0xAC, 0xAD, 0xB8, 0xCB,
//            0xD6, 0xAA, 0x5B, 0xD7,
//            0x32, 0xA6, 0x97, 0x2E,
//            0x58, 0xAA, 0x5A, 0xF3
//        };
//    }

    printf("80-bit or 128-bit key (input): ");
    for (int i = 0; i < 16; i++) {
        printf("%02X", key[i]);
        /*if (i < 9) printf(" "); */
    }
    printf("\n\n");

    KEY k;  /* structure to hold whitening & round keys */

    /* Run the key schedule */
    keySchedule(key, &k);

    /* Print whitening keys */
    printf("Whitening keys:\n");
    printf(" wKey[0] = %08lX\n", k.wKey[0]);
    printf(" wKey[1] = %08lX\n\n", k.wKey[1]);

    /* Print round keys */
    printf("Round keys (RN=%d):\n", RN);
    for (int i = 0; i < RN; i++) {
        printf(" rKey[%02d] = %08lX\n", i, k.rKey[i]);
    }




    return 0;
}
