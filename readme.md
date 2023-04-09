# Obtener STS Token de AWS

<img src="./images/iam-aws-sts.png" width="120px">

Para utilizar este script se deben contar con configuraciones iniciales

## Requisitos:

- Usuario de IAM
- Access Keys de usuario de IAM
- ARN de dispositivo asociado a usuario de IAM
- Configuración de archivos config y credentials de AWS
- Colocar el arn del dispositivo MFA dentro del script en la línea 58 como valor de la variable MFA_SERIAL
- Colocar la región de AWS donde trabajará el usuario dentro del script en la línea 52 como valor de la variable DEFAULT_REGION
<br/>
### Primer paso
<br/>

Generar perfil base de AWS para CLI en el que se utilizarán las credenciales del usuario de IAM que servirán para poder obtener el token STS

**Ejemplo archivo config:**

```properties
isaac@vader~$ cat ~/.aws/config
[profile nubexpert]
region = us-east-1
output = json
```

**Ejemplo archivo credentials (Sustituir asteriscos por access y secret key reales del usuario de IAM):**

```properties
isaac@vader~$ cat ~/.aws/config
[nubexpert]
aws_access_key_id = ******************
aws_secret_access_key = ****************************
region = us-east-1
```

Ya con los requisitos podemos realizar la ejecución del script, para esto el script espera un par de parámetros, el primero es el perfil de AWS que se acaba de configurar previamente, que será el que utilizará para poder autenticarse con AWS y solicitar el token STS, el segundo parámetro es el nombre del perfil que querramos asignar a las nuevas credenciales generadas y que será utilizado posteriormente para el uso de los recursos (para este ejemplo mfa), como se muestra a continuación:

```properties
isaac@vader~$ ./getTokenSTSAWS.sh nubexpert mfa
Token code for MFA Device (arn:aws:iam::123456789012:mfa/iam-user): 123456
INFO [2023-04-08 21:11:16]: ---------------------------------------------------------------------------------------
INFO [2023-04-08 21:11:16]: Generating new IAM STS Token ...
INFO [2023-04-08 21:11:16]: ---------------------------------------------------------------------------------------
INFO [2023-04-08 21:11:19]: ---------------------------------------------------------------------------------------
INFO [2023-04-08 21:11:19]: STS Session Token generated and updated in AWS credentials file successfully
INFO [2023-04-08 21:11:19]: ---------------------------------------------------------------------------------------
```

Ahora ya podremos utilizar nuestros recursos desde la CLI utilizando el perfil generado desde el script, como se muestra a continuación

```properties
isaac@vader~$ aws s3 ls --profile mfa          
2017-07-20 19:03:36 bucket-1
2017-10-07 11:24:52 bucket-2
```

Este token tiene un periodo de duración de 12 horas por default, esto puede modificarse si es requerido con el siguiente parámetro dado en segundos ***--duration-seconds***, este debe ir en el comando que se encuentra en la línea 82 del script.
