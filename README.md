# Nombres_Argentina

El Gobierno de la Nación Argentina en su programa de datos Abiertos hizo público hacia el año 2017 el siguiente sitio donde se puede ver qué tan popular fue tu nombre a lo largo de la historia. Es remarcable el trabajo de publicar una gran cantidad de datos, muchos de los cuales son anteriores a cualquier computadora y tuvieron que ser pasados a mano a partir de documentos en papel.

https://nombres.datos.gob.ar/

También hay un link al conjunto de datos con la que se alimenta la página

En la página
https://datos.gob.ar/dataset/otros-nombres-personas-fisicas

Directamente el Dataset
https://infra.datos.gob.ar/catalog/otros/dataset/2/distribution/2.1/download/historico-nombres.zip



## Problemas

Uno de los problemas que encontré en aquel momento fue que la búsqueda que hace el sito es a nombre completo es decir, si uno busca "Juan" muestra la cantida de gente que se llamón "Juan" a secas. no cuenta los "Juan Carlos" ó los "Juan José"

Por ejemplo:

- Juan: 44756 personas desde 1922 a 2015
- Juan Carlos: 290266 personas en el mismo perído
- Juan José: 95390 personas


## La motivación para hacer esto
Estoy aprendiendo R, y quería utilizar en dataset de alguna magnitud que tuviera algunos desafíos.
Finalmente, terminé utilizando otras herramientas más clásicas como sed and awk para hacerla manipulación inicial y limpieza de los datos.


## Uso.

Esto fue desarrolado con las utilidades de Ubuntu en Windows Susbistem for Linux 2. No puedo garantizar que funcione en otras distribuciones de linux.

1) Clonar el repositorio (o bajarlo)
2) Bajar una copia del dataset del Gobierno y descomprimirla. No está en este repositorio. Es un archivo csv llamado "historico-nombres.csv"
3) Ejecutar

    sed -f Sed_Script.txt historico-nombres.csv|awk -f Pre_awk.txt

Demora unos minutos. Son varias verificaciones con expresiones regulares sobre más de nueve millones de registros. Con esto se van a generar dos archivos. Uno llamado "Nombres-Limpio.csv" que tiene todos los nombres que se pudieron corregir con el script y otro llamado "Nombres-Problema.csv" que tiene 85 entradas que no se solucionaron y que hay que corregir a mano con un editor de texto.

4) Corregir a mano el archivo "Nombres-Problema.csv" y guardarlo como "Nombres-Problema-Corregido.csv". Luego volver a unir y limpiar

    cat Nombres-Problema-Corregido.csv >> Nombres-Limpio.csv && mv Nombres-Limpio.csv Nombres.csv && rm Nombres-Problema.csv

5) Post procesar para agregar un archivo de nombres completos y un archivo de nombres individuales.

    awk -f Post_awk.txt Nombres.csv && rm Nombres.csv


Con esto ya estamos en condiciones de importar los datos a R y comenzar a hacer algunas cosas. En el archivo "Nombres.r" hay varios ejemplos de uso.


# Cómo sigue

Por comentarios, sugerencias o lo que sea. Por aquí, o por pm en Reddit al usuario u/CalmRott7915

Mi objetivo final es hacer una aplicación Shiny donde puedan poner el nombre de sus compañeros de escuela y les diga qué probabilidad hay que sean de una determinada clase (Julio de un año hasta Junio del siguiente) usando un método Bayesiano. Contribuciones y ayuda, más que bienvenidas.

Esto es libre para usarlo como quieran, el único pedido es que si lo úsan me den crédito donde lo usen.









