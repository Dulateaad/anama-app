# Отладка загрузки изображений

## Проблема
Изображения знаменитостей не отображаются в карточках "Гении в зоне риска".

## Решение

### 1. Использован CachedNetworkImage
- Кэширование изображений
- Улучшенная обработка ошибок
- Fallback на Image.network при ошибке

### 2. CSP заголовки
- Обновлен `web/index.html` для разрешения загрузки изображений с любых источников

### 3. Fallback механизм
Если CachedNetworkImage не может загрузить изображение:
- Автоматически пробуется Image.network
- При ошибке показывается эмодзи вместо фото

## Проверка URL изображений

Все URL были проверены через curl и доступны:
- ✅ Маркус Перссон: `https://cdn.prod.elseone.nl/uploads/2016/02/2668363-1.jpg`
- ✅ Джефф Безос: `https://www.investopedia.com/thmb/...`
- ✅ Билли Айлиш: `https://bridgetv.ru/s/uploads/...`
- ✅ MrBeast: `https://www.netinfluencer.com/wp-content/uploads/...`
- ✅ Деми Ловато: `https://sefon.pro/img/artist_photos/demi-lovato.jpg`
- ✅ Леди Гага: `https://icdn.lenta.ru/images/...`
- ✅ Логан Пол: `https://static.wikia.nocookie.net/...`

## Возможные проблемы

1. **CORS политика** - некоторые серверы могут блокировать загрузку
2. **Ограничения домена** - некоторые URL могут требовать рефера или авторизации
3. **Кэш браузера** - старые версии могут быть в кэше

## Решение через Firebase Functions (если проблема сохранится)

Можно создать proxy функцию, которая будет загружать изображения и отдавать их через Firebase Hosting:

```javascript
exports.proxyImage = functions.https.onRequest(async (req, res) => {
  const imageUrl = req.query.url;
  const response = await fetch(imageUrl);
  const buffer = await response.arrayBuffer();
  res.set('Content-Type', response.headers.get('content-type'));
  res.send(Buffer.from(buffer));
});
```

## Логирование

В консоли браузера будут видны ошибки загрузки с URL и описанием проблемы.

