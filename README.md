# API de gestión de activos corporativos (Ruby on Rails 8 API)

[![CI](https://github.com/KevinAndrey96/rails-api-corporate-asset-management/actions/workflows/ci.yml/badge.svg)](https://github.com/KevinAndrey96/rails-api-corporate-asset-management/actions/workflows/ci.yml)
![Ruby 3.4](https://img.shields.io/badge/Ruby-3.4-CC342D?logo=ruby&logoColor=white)
![Rails 8.1 API](https://img.shields.io/badge/Rails-8.1%20API-D30001?logo=rubyonrails&logoColor=white)
![OpenAPI 3.1](https://img.shields.io/badge/OpenAPI-3.1-6BA539?logo=openapiinitiative&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-3-003B57?logo=sqlite&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)
[![Licencia MIT](https://img.shields.io/badge/licencia-MIT-green)](LICENSE)

**API REST en Ruby on Rails 8** para controlar el **inventario de activos de una empresa** (portátiles, equipos de escritorio, monitores, celulares y vehículos), los **colaboradores** que los reciben y el **ciclo de préstamo y devolución**. Genera **alertas de vencimiento del SOAT y de la revisión técnico-mecánica** de la flota y de **devoluciones atrasadas**.

Es una referencia de buenas prácticas para APIs JSON: autenticación con **tokens Bearer** de lectura o escritura, errores **RFC 9457** (`application/problem+json`), paginación con cabecera **`Link` RFC 8288**, filtros y ordenamiento en lista blanca, límite de solicitudes, concurrencia segura y contrato **OpenAPI 3.1** verificado por las pruebas.

> Los datos de demostración son **ficticios**.

## Características

- **Préstamo y devolución transaccionales**: el activo se bloquea durante la entrega y un índice único parcial garantiza una sola asignación abierta por activo, incluso con solicitudes simultáneas.
- **Máquina de estados del activo**: `available`, `assigned`, `maintenance` y `retired`. Solo cambia a asignado al entregarse y no sale de ese estado hasta registrar la devolución; una devolución con daño lo envía a mantenimiento.
- **Vehículos con documentos obligatorios** (Ley 769 de 2002): placa de carro `ABC123` o de moto `ABC12D`, vencimiento del SOAT y de la revisión técnico-mecánica.
- **Alertas de cumplimiento** con ventana configurable (`within_days`), ordenadas por urgencia y con mensaje legible.
- **Integridad referencial**: no se eliminan activos ni colaboradores con historial, y un colaborador con activos asignados no puede desactivarse.
- **Protección de datos personales** (Ley 1581 de 2012): el número de documento se busca de forma exacta pero solo se expone enmascarado (`****4050`).
- **Tokens almacenados como digest SHA-256**, con acceso `reader` o `editor`, revocables y con registro de último uso.
- **Mensajes en español** para validaciones, conflictos y alertas.

## Endpoints

Todos bajo `/api/v1` y con `Authorization: Bearer <token>`. El contrato completo está en [`public/openapi.yaml`](public/openapi.yaml), publicado en `/openapi.yaml`.

| Método | Ruta | Descripción |
| --- | --- | --- |
| `GET` | `/employees` | Colaboradores, filtros `department`, `active`, `document_number`, `q`, `sort` |
| `GET` | `/employees/{id}` | Colaborador con los activos que tiene asignados |
| `POST` `PATCH` `DELETE` | `/employees`, `/employees/{id}` | Gestión de colaboradores (editor) |
| `GET` | `/assets` | Activos, filtros `category`, `status`, `q`, `sort` |
| `GET` | `/assets/{id}` | Activo con su historial de asignaciones |
| `POST` `PATCH` `DELETE` | `/assets`, `/assets/{id}` | Gestión de activos, mantenimiento y baja (editor) |
| `GET` | `/assignments` | Asignaciones, filtros `state` (`open`, `returned`, `overdue`), `asset_id`, `employee_id` |
| `POST` | `/assignments` | Entrega un activo disponible a un colaborador activo (editor) |
| `PATCH` | `/assignments/{id}/return` | Registra la devolución, opcionalmente a mantenimiento (editor) |
| `GET` | `/alerts` | SOAT y revisión técnico-mecánica vencidos o por vencer, y devoluciones atrasadas |

## Ejemplos

```bash
TOKEN=el-token-de-tu-cliente
curl -H "Authorization: Bearer $TOKEN" "http://localhost:3000/api/v1/assets?category=vehicle&sort=-purchase_cost"
curl -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"assignment":{"asset_id":3,"employee_id":4,"due_on":"2026-12-15"}}' http://localhost:3000/api/v1/assignments
curl -H "Authorization: Bearer $TOKEN" -X PATCH -H "Content-Type: application/json" \
  -d '{"assignment":{"needs_maintenance":true,"notes":"Pantalla rayada"}}' http://localhost:3000/api/v1/assignments/7/return
curl -H "Authorization: Bearer $TOKEN" "http://localhost:3000/api/v1/alerts?within_days=60"
```

Alerta de cumplimiento:

```json
{
  "kind": "technical_review",
  "severity": "expired",
  "message": "La revisión técnico-mecánica del vehículo VEH-0002 venció el 20 de noviembre de 2026 (hace 6 días).",
  "due_on": "2026-11-20",
  "days_left": -6,
  "asset": { "id": 7, "tag": "VEH-0002", "category": "vehicle", "brand": "Chevrolet", "model": "NHR Reward 2021", "plate": "TSM905" }
}
```

Error RFC 9457 al prestar un activo que ya está asignado:

```json
{ "type": "about:blank", "title": "Conflicto con el estado actual", "status": 409,
  "detail": "El activo no está disponible para asignar (estado actual asignado)." }
```

| Código | Cuándo |
| --- | --- |
| `400` | Falta el objeto raíz (`employee`, `asset`, `assignment`) o un campo obligatorio |
| `401` | Token ausente, inválido o revocado (con cabecera `WWW-Authenticate: Bearer`) |
| `403` | Token de solo lectura en una operación de escritura |
| `404` | Recurso inexistente |
| `409` | La operación contradice el estado actual (activo no disponible, devolución repetida, eliminación con historial) |
| `422` | Validación fallida, con errores por campo en `errors` |
| `429` | Más de 300 solicitudes por minuto con el mismo token |

## Arquitectura

| Capa | Implementación |
| --- | --- |
| Dominio | `Employee`, `Asset`, `Assignment`, `ApiClient` con restricciones `CHECK`, índices únicos y un índice parcial de asignaciones abiertas |
| Casos de uso | `AssetCheckout` (entrega con bloqueo), `AssetReturn` (devolución), `ComplianceAlerts` (vencimientos y atrasos) |
| Transporte | Controladores `Api::V1` sobre `ActionController::API`, serializadores explícitos y errores `problem+json` centralizados |
| Infraestructura | Rails 8.1 en modo API, SQLite, Solid Cache, Thruster y Docker con health check |

## Inicio rápido con Docker

```bash
cp .env.example .env
# Completa SECRET_KEY_BASE (openssl rand -hex 64) y BOOTSTRAP_API_TOKEN (openssl rand -base64 32)
docker compose up --build
curl -H "Authorization: Bearer <BOOTSTRAP_API_TOKEN>" http://localhost:3000/api/v1/alerts
```

En el primer arranque se crea la base de datos, el cliente `bootstrap` con acceso de escritura y los datos de demostración (`LOAD_DEMO_DATA=true`): 5 colaboradores, 8 activos y 5 asignaciones.

Gestión de tokens:

```bash
docker compose exec api bin/rails "api_clients:issue[tablero-bi,reader]"
docker compose exec api bin/rails "api_clients:revoke[tablero-bi]"
```

## Desarrollo local

Requisitos: Ruby 3.4 y SQLite 3.

```bash
bundle install
bin/rails db:prepare
BOOTSTRAP_API_TOKEN=$(openssl rand -base64 32) LOAD_DEMO_DATA=true bin/rails db:seed
bin/rails server
```

## Calidad y seguridad

```bash
bin/rails test               # 59 pruebas de dominio, casos de uso, autenticación, endpoints y contrato OpenAPI
bin/rubocop                  # estilo rubocop-rails-omakase
bin/brakeman                 # análisis estático de seguridad
bin/bundler-audit            # dependencias con vulnerabilidades conocidas
bin/smoke-test URL TOKEN     # prueba de humo contra un contenedor en ejecución
```

El pipeline de GitHub Actions ejecuta Brakeman, bundler-audit, RuboCop, la suite de pruebas y construye la imagen de producción para correr la prueba de humo.

## Historia del proyecto

El repositorio nació en agosto de 2017 como un ejercicio universitario de Rails 5.1 en modo API con ocho recursos CRUD generados por scaffold. Ese código se conserva en la etiqueta [`v0.1-rails-5.1-api-scaffold-2017`](https://github.com/KevinAndrey96/rails-api-corporate-asset-management/tree/v0.1-rails-5.1-api-scaffold-2017). En 2026 se reescribió por completo sobre Rails 8.1 con un dominio coherente, autenticación, contrato OpenAPI y Docker.

## Licencia

[MIT](LICENSE) © 2017-2026 Kevin Andrey Herrera Silva
