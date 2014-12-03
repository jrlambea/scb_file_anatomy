#!/bin/bash

#Función para leer bytes
function readByte
{
    len=$1
    result=`od -t d "${file}" --read-bytes=${len} -An --skip-bytes="${index}"| tr " " "\0"`
    index=$(($index + $len))
}

#Función para leer chars
function readChars
{
    len=$1
    result="`od -t c "${file}" --read-bytes=${len} -An --skip-bytes="${index}"| tr " " "\0"`"
    index=$(($index + $len))

}

#Función para extraer una sección de datos
function dumpData
{
    len=$1
    tag="${2}"
    dd if=$file of=${file}.${tag} skip=$index bs=1  count=$len status=noxfer 2> /dev/null
    index=$(($index + $len))
}

#Función para tratar las páginas
function readPage
{
    readChars 3
    pformat="${result}"

    #Bytes de comprobación, si no son SCP sale del script
    if [[ $pformat == "SCP" ]]; then
        echo "SCP magic number ok."
    else
        echo "There was an error converting this document."
        exit 1
    fi

    readByte 2
    
    current_page="${result}"
    echo "Current page: ${current_page}"
    
    index=$(( $index + 8 ))
 
    readByte 1
    pageCompresionRatio="${result}"
    echo "Page compresion ratio: $pageCompresionRatio"

    if [[ $pageCompresionRatio -gt 0 ]];then
        echo "Compressed: yes"
    else
        echo "Compressed: no"
    fi

    readByte 4
    page_size="${result}"
    echo "Page size: $page_size"

    dumpData $page_size "page_${page_index}"
    
    #Si la compresión es > 0 entonces descomprime, de otra manera salta un byte
    if [[ $pageCompresionRatio -gt 0 ]];then
        echo -n "Uncompressing SWF page ... "
        cat "${file}.page_${page_index}" | zlib-flate -uncompress > "${file}.page_${page_index}.data"
        rm "${file}.page_${page_index}"
        echo "${file}.page_${page_index}.data"
    else
        mv "${file}.page_${page_index}" "${file}.page_${page_index}.data"
        index=$(( $index + 1 ))
    fi

    echo "Uncompressed SWF header len: `ls -ltr "${file}.page_${page_index}.data" | cut -d" " -f5`"""
    
    echo "Current position: $index"
    
}

if [[ $# -ne 1 ]]; then
    echo "USAGE: $0 file[SCB]"
    exit 1
fi

file="$1"

index=0
result=""

readChars 3

format="${result}"""

#Bytes de comprobación, si no son SCB sale del script
if [[ $format == "SCB" ]]; then
    echo "SCB Magic number ok."
else
    echo "Invalid format file."
    exit 1
fi

readByte 1

file_version="${result}"
echo "SCB version: $file_version"

index=$(( $index + 4 ))

readChars 3
hformat="${result}"
echo "-----------[SCH]-------------"

if [[ $hformat == "SCH" ]]; then
    echo "SCH Magic number ok."
else
    echo "There was an error converting this document."
    exit 1
fi

readByte 4
echo "Header size: $result"

readByte 4
echo "Doc id: $result"

readByte 1
echo "Doc Type: $result"

readByte 2
page_count="${result}"
echo "Page count: $page_count"

readByte 2
echo "Width: $result"

readByte 2
echo "Height: $result"

readByte 2
echo "Offset: $result"

readByte 1
echo "Variable misteriosa: $result"

readByte 1
compression_ratio="${result}"
echo "Compresion ratio: $compression_ratio"

if [[ $compression_ratio -gt 0 ]];then
    echo "Compressed: yes"
else
    echo "Compressed: no"
fi

readByte 4
echo "Tamaño del header SWF: $result"

echo "Posición actual: $index"

echo "-----------[SWF]-------------"

dumpData $result swfheader
echo -n "Uncompressing SWF header ... "
cat "${file}.swfheader" | zlib-flate -uncompress > "${file}.swfheader.swf"
rm "${file}.swfheader"
echo "${file}.swfheader.swf"
echo "Uncompressed SWF header len: `ls -ltr "${file}.swfheader.swf" | cut -d" " -f5`"

page_index=1
echo "PageIndex: ${page_index}"
echo "Current position: $index"


while [[ $page_index -le $page_count ]]; do
    echo "-----------[PAGE${page_index}]-------------"
    readPage 
    page_index=$(($page_index + 1))
done

echo "--------[Reconstruction]----------"
page_index=1
echo "Creating new SWF from header."
cat "${file}.swfheader.swf" > reconstructed.swf

while [[ $page_index -le $page_count ]]; do
    echo "Adding page $page_index\\$page_count."
    cat "${file}.page_${page_index}.data" >> reconstructed.swf
    echo -en "\0" >> reconstructed.swf
    page_index=$(($page_index + 1))
done
