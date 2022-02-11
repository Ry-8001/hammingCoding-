#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define MAX_N_BYTES 256  //  actually this value -1 but whatever


typedef unsigned char BYTE;


char BYTE_BINARY_STRING[9] = {0};
#define BYTE_BINARY_REPRESENTATION(byte) (sprintf(BYTE_BINARY_STRING, "%c%c%c%c%c%c%c%c",\
   (byte&0x80)?'1':'0',\
   (byte&0x40)?'1':'0',\
   (byte&0x20)?'1':'0',\
   (byte&0x10)?'1':'0',\
   (byte&0x08)?'1':'0',\
   (byte&0x04)?'1':'0',\
   (byte&0x02)?'1':'0',\
   (byte&0x01)?'1':'0'), BYTE_BINARY_STRING)


/*
    inputBytes: array containing the raw data
                each element in this array contains a single byte
                of information
                    
                  data0|data1
                  data2|data3
                  ...

    nInputBytes: number of elements in array inputBytes
                  
    
    encodedBytes: array containing data and parity values, concatenated like this:
                   data0|parity0
                   data1|parity1
                   ...
                   
                   dataN is nth 4-bit part of the original input bytes
                   parityN is its calculated parity value for that data
                   
                   
                   this array will be filled in the assembly code
                   you are going to write for the project!
    
    nEncodedBytes: number of elements you will put in array encodedBytes
                  in your project this number is always equals to inputNBytes*2
    
    H: 8x4 matrix
    
    Hmr: upper 4x4 part of H matrix (H without identity part)
    
    
    
    
    
    return value: nothing
*/
void encode_data(BYTE* inputBytes, int nInputBytes, BYTE* encodedBytes, int nEncodedBytes, int* H, int* Hmr);








/*
    encodedBytes: array containing the encoded data
    
                  this array is filled in encode_data function
                  you are going to write for your project!

    nEncodedBytes: number of elements in array encodedBytes
                  in your project this number is always equals to inputNBytes*2
    
    decodedBytes: array containing ONLY data values, separated from their parity and concatenated like this:
                   data0|data1
                   data2|data3
                   ...
                   
                   
                   this array will be filled in the assembly code
                   you are going to write for the project!
    
    nDecodedBytes: number of elements you will put in array decodedBytes
                  in your project this number is always equals to inputNBytes
    
    H: 8x4 matrix
    
    Hmr: upper 4x4 part of H matrix (H without identity part)
    
    
    errorStatus:  for EVERY bit in the ENCODED bytes, if there is an error in
                  that specific bit, corresponding bit in the errorStatus
                  should be 1, if there is not error corresponding bit in the
                  errorStatus should be 0
                  
                  see pdf file for an example case
                  
                  this array will be filled in the assembly code
                  you are going to write for the project!
    
    
    
    
    return value: number of corrupted bytes in the encodedBytes array
*/
int decode_data(BYTE* encodedBytes, int nEncodedBytes, BYTE* decodedBytes, int nDecodedBytes, int* H, int* Hmr, BYTE* errorStatus);



int corrupt_data(BYTE* encodedBytes, int nEncodedBytes)
{
    const int corrupt_chance = 50;
    int i;
    int corrupted_count = 0;
    
    for (i = 0; i < nEncodedBytes; ++i)
    {
        int corrupt_probability = (rand() % 100) + 1;  //  [1, 100]
        if (corrupt_probability <= corrupt_chance)
        {
            //  corrupt one of the bits
            int bit_index_to_corrupt = rand() % 8;  //  [0, 7]
            
            int oldValue = encodedBytes[i];
            printf("Byte before corrupt:\t%d, binary form:\t%s\n", oldValue, BYTE_BINARY_REPRESENTATION(oldValue));
            
            //  to ensure constant is integer
            int toggle_constant = 1;
            
            //  toggle a single bit
            encodedBytes[i] = encodedBytes[i] ^ (toggle_constant << bit_index_to_corrupt);
            
            int newValue = encodedBytes[i];
            printf("Byte after corrupt:\t%d, binary form:\t%s\n", newValue, BYTE_BINARY_REPRESENTATION(newValue));
            
            printf("Difference between old and new byte:%d\n", newValue - oldValue);
            
            ++corrupted_count;
        }
        else
        {
            //  do nothing
            ;
        }
    }
    
    printf("Number of corrupted bytes in corrupt_func:%d\n", corrupted_count);
    
    return corrupted_count;
}



int main(int argc, char* argv[])
{
    FILE* inputByteFile;
    int nInputBytes; 
    char byteString[MAX_N_BYTES];
    BYTE* inputBytes;
    int i;
    int j;
    
    
    BYTE* encodedBytes;
    int nEncodedBytes;
    
    
    BYTE* decodedBytes;
    int nDecodedBytes;
    BYTE* errorStatus;
    int nCorruptedBytes;
    int nDetectedCorruptedBytes;
    
    FILE* outputFile;
    
    
    FILE* inputMatrixFile;
    int H[32];
    int Hmr[16];  //  upper part of H matrix without identity part
    
    
    //  set random seed
    srand(time(NULL));
    
    //  check if number of arguments are correct
    if (argc != 3)
    {
        printf("Program can only be run with two arguments, input byte file and input matrix file!\n");
        return 1;
    }
    
    //  open input byte file
    inputByteFile = fopen(argv[1], "r");
    if (inputByteFile == NULL)
    {
        printf("Unable to open input byte file!\n");
        return 2;
    }
    
    
    //  read number of bytes in the input byte file
    fscanf(inputByteFile, "%d", &nInputBytes);
    printf("Number of bytes in input byte file:%d\n", nInputBytes);
    
    
    //  perform all required memory allocations
    inputBytes = malloc(nInputBytes * sizeof(BYTE));
    memset(inputBytes, 0, nInputBytes * sizeof(BYTE));
    
    encodedBytes = malloc(nInputBytes*2 * sizeof(BYTE));
    nEncodedBytes = nInputBytes*2;
    memset(encodedBytes, 0, nEncodedBytes * sizeof(BYTE));
    
    decodedBytes = malloc(nInputBytes * sizeof(BYTE));
    nDecodedBytes = nInputBytes;
    memset(decodedBytes, 0, nDecodedBytes * sizeof(BYTE));
    
    errorStatus = malloc(nInputBytes * sizeof(BYTE));
    memset(errorStatus, 0, nInputBytes * sizeof(BYTE));
    
    if (inputBytes == NULL || decodedBytes == NULL || encodedBytes == NULL || errorStatus == NULL)
    {
        printf("Unable to allocate memory !\n");
        return 3;
    }
    
    
    
    //  read byte information as string
    memset(byteString, 0, MAX_N_BYTES);
    fscanf(inputByteFile, "%s", byteString);
    printf("Byte string:%s\n", byteString);
    
    //  close byte input file
    fclose(inputByteFile);
    
    
    //  store bytes into integer (array) variable
    for (i = 0; i < nInputBytes; ++i)
    {
        int strStartIndex = i*8;
        int strtEndIndex = (i+1)*8 - 1;
        char temp[9] = {0};
        
        for (j = 0; j < 8; ++j)
        {
            temp[j] = byteString[strStartIndex+j];
        }
        
        printf("temp:%s\n", temp);
        inputBytes[i] = strtol(temp, NULL, 2);
        printf("Decimal value of byte %d: %d, binary form:%s\n", i, inputBytes[i], BYTE_BINARY_REPRESENTATION(inputBytes[i]));
    }
    
    
    
    //  read input matrix
    inputMatrixFile = fopen(argv[2], "r");
    if (inputMatrixFile == NULL)
    {
        printf("Unable to open input matrix file!\n");
        return 4;
    }
    
    //  input matrix file always contains a 8x4 matrix
    for (i = 0; i < 32; ++i)
        fscanf(inputMatrixFile, "%d", &(H[i]));
    for (i = 0; i < 16; ++i)
        Hmr[i] = H[i];
    
    //  close matrix input file
    fclose(inputMatrixFile);
    
    
    //  encode the input data
    encode_data(inputBytes, nInputBytes, encodedBytes, nEncodedBytes, H, Hmr);
    
    //  corrupt encoded data
    nCorruptedBytes = corrupt_data(encodedBytes, nEncodedBytes);
    
    //  decode corrupted encoded data
    nDetectedCorruptedBytes = decode_data(encodedBytes, nEncodedBytes, decodedBytes, nDecodedBytes, H, Hmr, errorStatus);
    
    
    //  create an output file for writing results
    outputFile = fopen("output.txt", "w");
    if (outputFile == NULL)
    {
        printf("Unable to open output file!\n");
        return 5;
    }
    
    
    //  write everything to output file
    for (i = 0; i < 32; ++i)
        fprintf(outputFile, "%d ", H[i]);
    fprintf(outputFile, "\n");
    
    
    fprintf(outputFile, "%s\n", byteString);
    
    
    fprintf(outputFile, "%d\n", nInputBytes);
    for (i = 0; i < nInputBytes; ++i)
    {
        fprintf(outputFile, "%d ", inputBytes[i]);
        fprintf(outputFile, "%s ", BYTE_BINARY_REPRESENTATION(inputBytes[i]));
    }
    fprintf(outputFile, "\n");
    
    
    fprintf(outputFile, "%d\n", nEncodedBytes);
    for (i = 0; i < nEncodedBytes; ++i)
    {
        fprintf(outputFile, "%d ", encodedBytes[i]);
        fprintf(outputFile, "%s ", BYTE_BINARY_REPRESENTATION(encodedBytes[i]));
    }
    fprintf(outputFile, "\n");
    
    
    fprintf(outputFile, "%d\n", nDecodedBytes);
    for (i = 0; i < nDecodedBytes; ++i)
    {
        fprintf(outputFile, "%d ", decodedBytes[i]);
        fprintf(outputFile, "%s ", BYTE_BINARY_REPRESENTATION(decodedBytes[i]));
    }
    fprintf(outputFile, "\n");
    
    
    fprintf(outputFile, "%d\n", nEncodedBytes);
    for (i = 0; i < nEncodedBytes; ++i)
    {
        fprintf(outputFile, "%d ", errorStatus[i]);
        fprintf(outputFile, "%s ", BYTE_BINARY_REPRESENTATION(errorStatus[i]));
    }
    fprintf(outputFile, "\n");
    
    
    fprintf(outputFile, "%d\n", nCorruptedBytes);
    fprintf(outputFile, "%d\n", nDetectedCorruptedBytes);
    
    //  close output file
    fclose(outputFile);
    
    
    //  deallocate allocated data
    //should not be necessary at program end
    free(inputBytes);
    free(encodedBytes);
    free(decodedBytes);
    free(errorStatus); 
    
    return 0;
}
