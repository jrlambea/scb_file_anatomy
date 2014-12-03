# SCB File Anatomy

1. Introducción
    1. Propósito
    2. ¿Qué es un fichero SCB?
2. Estructura
    1. Secciones
        1. SCB, estructura de libro
        2. SCH, estructura de cabecera
        3. SCP, estructura de página
3. Algoritmos
    1. Compresión
    2. Encriptación
4. Comentarios

##1.Introducción

###1.1 Propósito
Con este documento se pretende plasmar el resultado de un breve estudio de ingeniería inversa al formato de ficheros SCB, formato desarrollado por la empresa [Scribd Inc.](https://www.scribd.com/about) como una alternativa de documento portable al ya existente formato público y estándar PDF. El resultado debe facilitar a los desarrolladores a crear nuevos lectores de ficheros SCB, así como facilitar la creación de contenido en ese formato.

###1.2 ¿Qué es un fichero SCB?
El fichero contiene el libro objeto en formato `SWF` y desglosado, por un lado, la cabecera (2.1.2), y por otro lado, cada una de las páginas del libro, por lo que es posible reconstruir un fichero `SWF` válido concatenando la cabecera y cada una de las páginas añadiendo un byte nulo entre cada una de ellas. Se ha desarrollado una prueba de concepto en `bash` que reconstruye el fichero `SWF` a partir de uno `SCB` siempre y cuando este no esté encriptado, lo podéis encontrar [aquí](https://github.com/spageek/scb_file_anatomy/blob/master/p.o.c./scb2swf.sh).

##2.Estructura
###2.1 Secciones
####2.1.1 SCB, estructura de ibro
<table>
    <tr>
        <td>bytes</td>
        <td>Tipo</td>
        <td>Descripción</td>
    </tr>
    <tr>
        <td>0x03</td>
        <td>char[]</td>
        <td>_Magic number_, identifica el formato del fichero, siempre contiene el valor 0x53, 0x43, 0x42 (SCB) para el formato objeto de este documento, se intuye que en referencia a __SC__ribd __B__ook.</td>
    </tr>
    <tr>
        <td>0x01</td>
        <td>byte</td>
        <td>Versión del fichero, en el fichero de muestra este byte tiene un valor de 0x01.</td>
    </tr>
    <tr>
        <td>0x04</td>
        <td>dummy</td>
        <td>Bytes sin función conocida.</td>
    </tr>
</table>

####2.1.2 SCH, estructura de cabecera
<table>
    <tr>
        <td>bytes</td>
        <td>Tipo</td>
        <td>Descripción</td>
    </tr>
    <tr>
        <td>0x03</td>
        <td>char[]</td>
        <td>_Magic number_, identifica el inicio de la cabecera, siempre contiene el valor 0x53, 0x43, 0x48 (SCH), se intuye que en referencia a __SC__ribd __H__eader.</td>
    </tr>
    <tr>
        <td>0x04</td>
        <td>integer</td>
        <td>Tamaño de la cabecera en bytes.</td>
    </tr>
    <tr>
        <td>0x04</td>
        <td>integer</td>
        <td>Doc ID, identificador del documento.</td>
    </tr>
    <tr>
        <td>0x01</td>
        <td>byte</td>
        <td>Tipo del documento (falta saber la relación entre diferentes valores y el tipo real).</td>
    </tr>
    <tr>
        <td>0x02</td>
        <td>single</td>
        <td>Total de páginas.</td>
    </tr>
    <tr>
        <td>0x02</td>
        <td>single</td>
        <td>Anchura del libro en píxeles.</td>
    </tr>
    <tr>
        <td>0x02</td>
        <td>single</td>
        <td>Altura del libro en píxeles.</td>
    </tr>
    <tr>
        <td>0x02</td>
        <td>single</td>
        <td>Offset de página.</td>
    </tr>
    <tr>
        <td>0x01</td>
        <td>byte</td>
        <td>Bytes sin función conocida.</td>
    </tr>
    <tr>
        <td>0x01</td>
        <td>byte</td>
        <td>Ratio de compresión, en caso de tener como valor un cero el libro no estaría comprimido.</td>
    </tr>
    <tr>
        <td>0x04</td>
        <td>integer</td>
        <td>Tamaño del bloque de datos de la cabecera.</td>
    </tr>
    <tr>
        <td>0x??</td>
        <td>data</td>
        <td>La longitud de este bloque depende del valor del campo anterior. El contenido es un fichero SWF el cual todavía está pendiente el análisis.</td>
    </tr>
</table>

####2.1.2 SCP, estructura de página
La próxima estructura de datos se repite por cada una de las páginas que contiene el documento.
<table>
    <tr>
        <td>bytes</td>
        <td>Tipo</td>
        <td>Descripción</td>
    </tr>
    <tr>
        <td>0x03</td>
        <td>char[]</td>
        <td>_Magic number_, identifica el inicio de la página, siempre contiene el valor 0x53, 0x43, 0x50x0&(SCP), se intuye que en referencia a __SC__ribd __P__age.</td>
    </tr>
    <tr>
        <td>0x02</td>
        <td>single</td>
        <td>Número de página actual.</td>
    </tr>
    <tr>
        <td>0x08</td>
        <td>dummy</td>
        <td>Bytes sin función conocida.</td>
    </tr>
    <tr>
        <td>0x01</td>
        <td>byte</td>
        <td>Ratio de compresión de la página, en caso de tener como valor un cero la página no estaría comprimida.</td>
    </tr>
    <tr>
        <td>0x04</td>
        <td>integer</td>
        <td>Tamaño en bytes de la página.</td>
    </tr>
    <tr>
        <td>0x??</td>
        <td>data</td>
        <td>La longitud de este bloque depende del valor del campo anterior. El contenido son los datos que conforman la página pero no se ha podido averiguar todavia cual es el formato real, se conjetura que hay una dependencia entre el `SWF` extraído en la sección anterior y los datos de cada una de las páginas.</td>
    </tr>
    <tr>
        <td>0x01</td>
        <td>byte</td>
        <td>Este byte **sólo** existe en caso de que la página **no** esté comprimida, en otro caso este byte no existe.</td>
    </tr>
</table>

##3. Algoritmos
###1. Compresión
En la especificación de este formato se pensó para la compresión utilizar la librería ampliamente utilizada [zlib](https://en.wikipedia.org/wiki/Zlib). Esto permite que los datos sean facilmente comprimidos/descomprimidos sin necesidad de hacer ingeniería inversa de ningún algoritmo. Un ejemplo de descompresión en caso de que tuvieramos los datos a descomprimir aislados en un fichero `data.compressed`:

    $ cat data.compressed | zlib-flate -uncompress > data.uncompressed

Y lo mismo para la compresión:

    $ cat data.uncompressed | zlib-flate -compress > data.compressed

Para otros ejemplos de uso como librería en lenguajes de programación compilados, dirigíos a la [web oficial](http://zlib.net/) de la librería.

###3. Encriptación
Los documentos, a parte de comprimidos pueden estar encriptados con un sistema de encriptación simétrico (la misma clave para encriptar y desencriptar), este sistema es también ampliamente utilizado, es el `RC4`. Como dato extra, en el caso del visualizador de documentos flash está desarrollado por [Metal Hurlant](http://hurlant.com), una implementación de [RC4](http://en.wikipedia.org/wiki/RC4) para Action Script.

##4. Comentarios
Espero en lo personal que, si as caído en este documento, hayas encontrado lo que buscabas, cualquier comentario o si, por otra parte, eres un hacker con más información que aportar, no dudes en ponerte en contacto conmigo por correo electrónico a través de jr_lambea @ yahoo.com.
