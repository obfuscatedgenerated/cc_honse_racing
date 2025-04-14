"""
MIT License
 
Copyright (c) 2023 simadude
 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""
 
import argparse
import math
import os
import struct # dear python, please let me write binary without this tomfoolery.
 
def isCorrectNFP(data: str):
    allowedChars = set('0123456789ABCDEFabcdef \n')
    for char in data:
        if char not in allowedChars:
            return False
    return True
 
def getNFPColors(data: str):
    return set(data.lower())
 
def getNFPSize(data: str):
    lines = data.split("\n")
    maxWidth = 0
 
    for line in lines:
        width = len(line)
        if width > maxWidth:
            maxWidth = width
 
    maxHeight = len(lines)
 
    return maxWidth, maxHeight
 
def conciseNFP(data: str, maxWidth):
    newData = ""
    datalined = data.split("\n")
    for i, l in enumerate(datalined):
        newData += l + (" ")*(maxWidth-len(l))
        if i != len(datalined)-1:
            newData += "\n"
    return newData
 
 
def doRLE(data: str, width, height):
    encData = []
    # magic number so that text editors won't do shit
    encData.append(153)
    # just ORLI in ascii
    encData.append(79)
    encData.append(82)
    encData.append(76)
    encData.append(73)
    # width and height are 16 bit integers
    encData.append( width // 256)
    encData.append( width & 255)
    encData.append( height // 256)
    encData.append( height & 255)
 
    data = data.replace("\n", "")
    colors = getNFPColors(data)
    coldict = {}
    encData.append( len(colors))
    for i, col in enumerate(colors):
        coldict[col] = i
        encData.append(ord(col))
    # print(coldict)
    # return encData
    bitColor = max(math.ceil(math.log2(len(colors))), 1)
    maxRun = 2**(8 - bitColor)-1
    curColor = data[0]
    curRun = 0
    for i, c in enumerate(data):
        if c != curColor or curRun == maxRun:
            encData.append(coldict[curColor] * 2**(8-bitColor) + curRun)
            # encData.append(f"{coldict[curColor]}, {curRun}")
            curRun = 1
            curColor = c
        elif i == len(data)-1:
            encData.append(coldict[curColor] * 2**(8-bitColor) + curRun+1)
            # encData.append(f"{coldict[curColor]}, {curRun+1}")
        else:
            curRun += 1
    return encData
    
 
def processFile(inputFile, outputFile, silent):
    # t = time.perf_counter()
    if not silent: print(f"Input: {inputFile} | Output: {outputFile}")
    nfpData = ""
    nfpFileSize = 0
    with open(inputFile, "r") as f:
        nfpData = f.read()
        nfpFileSize = len(nfpData)
        if nfpData[-1] == "\n": # no trailing new lines, pls
            nfpData = nfpData[:-1]
        if not isCorrectNFP(nfpData):
            if not silent:print(f"THE INPUT FILE ISN'T AN NFP")
        l = getNFPColors(nfpData)
        l.discard("\n")
        if not silent:print(f"Total of {len(l)} colors in this image")
        if len(l) > 17:
            if not silent:print(f"Exiting, as over 17 colors shouldn't even be possible.")
            return
        colorbits = math.ceil(math.log2(len(l)))
        if not silent:print(f"This will end up with {colorbits} bits per color, and {8-colorbits} for color length.")
        if not silent:print(f"Allowing for {2**(8-colorbits)} pixels per byte maximum")
    # NFP is such a weird format some lines may be not the same length, which is bad
    # So we will try to "concise" our data first to make all of the lines the same length.
    width, height = getNFPSize(nfpData)
    if not silent:print(f"Size: {width}, {height}")
    nfpData = conciseNFP(nfpData, width)
    # We will assume here that nfpData is valid.
    encData = doRLE(nfpData, width, height)
    # if not silent:print(encData)
    res = (len(encData), nfpFileSize)
    if not silent:print(res)
    with open(outputFile, "wb") as f:
        f.write(struct.pack('B' * len(encData), *encData))
            
    return res
    
 
def processFolder(inputFolder, outputFolder):
    print("Checking existing files...")
    inputFolder = os.path.abspath(inputFolder)
    outputFolder = os.path.abspath(outputFolder)
    filesNFP = [f for f in os.listdir(inputFolder) if os.path.isfile((os.path.join(inputFolder, f))) and f[-4::1] == ".nfp"]
    if len(filesNFP) == 0:
        print("No .nfp files found, exiting.")
        return
    filesORLI = [f for f in os.listdir(outputFolder) if os.path.isfile((os.path.join(outputFolder, f))) and f[-5::1] == ".orli"]
    foundORLI = False
    for fileNFP in filesNFP:
        hasORLI = False
        print(f"{fileNFP} -> ", end="")
        for fileORLI in filesORLI:
            if fileNFP[:-4] == fileORLI[:-5]:
                foundORLI = True
                hasORLI = True
                print(f"{fileORLI}*")
                break
        if not hasORLI:
            print(fileNFP[:-4]+".orli")
        hasORLI = False
    if foundORLI:
        print("Since some files already have .orli pairs, exiting.")
        return
    # now let's concatenate the paths
    filesORLI = [os.path.join(outputFolder, f[:-4]+".orli") for f in filesNFP]
    filesNFP = [os.path.join(inputFolder, f) for f in filesNFP]
    totalNFP = 0
    totalRLI = 0
    for nfp, orli in zip(filesNFP, filesORLI):
        results = processFile(nfp, orli, True)
        totalRLI += results[0]
        totalNFP += results[1]
    print(totalRLI, totalNFP, f"Is around {math.floor((totalNFP/totalRLI)*100)/100} times smaller")
        
def main():
    parser = argparse.ArgumentParser(description='A tool for converting .nfp format into .orli (Obsi Run-Length Image) format.')
    parser.add_argument('input_path', type=str, help='Path to input file or folder')
    parser.add_argument('output_path', nargs='?', type=str, help='Path to output file or folder')
    args = parser.parse_args()
 
    input_path = args.input_path
    output_path = args.output_path
 
    if os.path.isdir(input_path):
        output_path = output_path or input_path
        processFolder(input_path, output_path)
    elif os.path.isfile(input_path):
        if not output_path:
            output_dir = os.path.dirname(input_path)
            filename = os.path.splitext(os.path.basename(input_path))[0]
            output_path = os.path.join(output_dir, filename + '.orli')
        processFile(input_path, output_path, False)
    else:
        parser.print_help()
 
if __name__ == '__main__':
    main()