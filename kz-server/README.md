# Anama KZ Server 🇰🇿

Сервер для хранения персональных данных в Казахстане согласно статье 12 Закона РК «О персональных данных и их защите».

## Требования

- Node.js 18+
- PostgreSQL 14+

## Установка

```bash
npm install
```

## Переменные окружения

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=anama_personal
DB_USER=anama
DB_PASSWORD=secure_password
ENCRYPTION_KEY=your-32-byte-key-here
PORT=3001
NODE_ENV=production
```

## Запуск

```bash
# Development
npm run dev

# Production
npm start
```

## Где развернуть в Казахстане

1. **PS Cloud** (ps.kz) — от 5000₸/мес
2. **Beeline Cloud** (cloud.beeline.kz) — от 7000₸/мес
3. **Yandex Cloud KZ** (cloud.yandex.kz) — от 3000₸/мес
4. **Kazteleport** (kazteleport.kz) — от 10000₸/мес

## API Endpoints

| Method | Endpoint | Описание |
|--------|----------|----------|
| POST | `/api/personal-data` | Сохранить персональные данные |
| GET | `/api/personal-data/:visitorId` | Получить данные |
| DELETE | `/api/personal-data/:visitorId` | Удалить данные (GDPR) |
| PATCH | `/api/personal-data/:visitorId/anonymize` | Анонимизировать |
| GET | `/api/personal-data/:visitorId/export` | Экспорт данных (GDPR) |

## Безопасность

- Все персональные данные шифруются AES-256
- Аудит всех операций
- Мягкое удаление для доказательства GDPR

