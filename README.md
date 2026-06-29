# Campaña de Vacunación Canina & Felina (Ecuador 2026)

Esta es una aplicación móvil multiplataforma desarrollada en **Flutter** utilizando **Clean Architecture** (Arquitectura Limpia) y el patrón de diseño **BLoC** para la gestión de estados. 

La aplicación permite a los vacunadores y coordinadores de brigada registrar y administrar dosis de vacunas aplicadas a perros y gatos en campo. Está diseñada con una filosofía **Offline-First**, permitiendo el ingreso de datos completos de forma segura sin conexión a internet y sincronizándolos automáticamente en segundo plano cuando se detecta red activa.

---

## 🚀 Características Clave

* **Offline-First Integrado:** Persistencia de datos local mediante **Hive** y sincronización en tiempo real o diferida con **Supabase** usando un sistema de colas administradas por `SyncBloc`.
* **Captura de Geolocalización GPS:** Integración con el sensor GPS (`geolocator`) para capturar de forma exacta la latitud y longitud del punto físico donde se aplicó la dosis.
* **Evidencia Fotográfica:** Captura de fotos en tiempo real usando la cámara del dispositivo (`image_picker`) para asociarla al registro de vacunación de la mascota.
* **Interfaz Pastel Amigable:** Una interfaz gráfica moderna, blanda y limpia basada en una paleta de **colores pastel** de alto contraste y legibilidad, ideal para el trabajo bajo luz solar directa en campo.
* **Seguridad de Acceso:** Validación de credenciales y redirección obligatoria para el cambio de clave si el usuario ingresa con credenciales por defecto.
* **Roles de Usuario:** Diferenciación de flujos de trabajo e interfaces entre *Vacunadores*, *Coordinadores de Brigada* y *Coordinadores de Campaña*.

---

## 📂 Estructura del Código (`lib/`)

El proyecto está organizado siguiendo los principios de la arquitectura limpia para garantizar alta mantenibilidad y testabilidad:

* **`core/`**: Configuraciones compartidas como el sistema de temas pastel, clases auxiliares y constantes globales (`AppColors` y `AppTheme`).
* **`domain/`** (Reglas de Negocio):
  * `entities/`: Modelos puros de datos en Dart sin dependencias externas (ej. `VaccinationRecord`, `AppUser`, `Sector`).
  * `repositories/`: Interfaces y contratos abstractos que describen los métodos requeridos para el flujo de datos.
* **`data/`** (Implementación de Datos):
  * `datasources/`:
    * `local/`: Persistencia en el almacenamiento del dispositivo utilizando la base de datos local **Hive**.
    * `remote/`: Lógica de consumo de API y almacenamiento en la nube utilizando **Supabase**.
  * `repositories/`: Implementación de los repositorios de dominio que orquestan las consultas de datos entre local y remoto.
* **`presentation/`** (Interfaz de Usuario):
  * `blocs/`: Gestión de estados reactivos utilizando `flutter_bloc` (`AuthBloc`, `VaccinationBloc` y `SyncBloc`).
  * `pages/`: Vistas divididas por módulos (`auth` para autenticación, `dashboard` para la vista principal y estadísticas, `admin` para gestión de sectores y asignaciones).

---

## 📱 Capturas de las Interfaces

A continuación se presentan las pantallas principales que componen el flujo de la aplicación:

### 1. Iniciar Sesión (Login)
*Fondo pastel claro amigable, soporte para recuperación de contraseña y diseño de campos de texto blandos.*

![Login](https://via.placeholder.com/280x600?text=Pantalla+de+Login)

### 2. Dashboard Principal (Vista de Vacunador / Coordinador)
*Métricas rápidas reactivas de dosis aplicadas, barra de estado de sincronización ("Conexión Estable") y listado dinámico de mascotas.*

![Dashboard](https://via.placeholder.com/280x600?text=Dashboard+Principal)

### 3. Formulario de Vacunación (Registro de Mascota)
*Formulario intuitivo que incluye selectores visuales de especie (Perro/Gato), captura automática de geolocalización GPS, selección de vacunas específicas por tipo de animal y captura de evidencia fotográfica.*

![Formulario](https://via.placeholder.com/280x600?text=Formulario+de+Vacunacion)

### 4. Panel de Administración
*Control de sectores geográficos y asignación de coordinadores y vacunadores.*

![Panel de Administracion](https://via.placeholder.com/280x600?text=Panel+de+Administracion)

---

## 🛠️ Cómo Compilar y Ejecutar

### Requisitos Previos
* Tener instalado **Flutter SDK** (versión recomendada >= 3.22.x).
* Tener configurado el **Android SDK** si compilas para móvil.

### Pasos para Ejecutar en Modo Desarrollo:
1. Clonar el repositorio y acceder a la carpeta raíz.
2. Descargar las dependencias del proyecto:
   ```bash
   flutter pub get
   ```
3. Ejecutar el proyecto en un emulador o dispositivo conectado:
   ```bash
   flutter run
   ```

### Pasos para Generar el APK de Instalación:
* **Para versión Release (Producción / Optimizado):**
  ```bash
  flutter build apk --release
  ```
  *(El archivo se generará en: `build/app/outputs/flutter-apk/app-release.apk`)*

* **Para versión Debug (Pruebas rápidas):**
  ```bash
  flutter build apk --debug
  ```
  *(El archivo se generará en: `build/app/outputs/flutter-apk/app-debug.apk`)*

---

## 👥 Integrantes del Proyecto

* **Nicolás Chiguano**
* **Gabriel Escobar**
