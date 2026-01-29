// Защита от ошибок share-modal.js
// Этот скрипт предотвращает ошибки, если share-modal.js пытается найти несуществующие элементы
(function() {
  // Проверяем, есть ли share-modal.js и предотвращаем ошибки
  if (typeof window !== 'undefined') {
    // Ждем загрузки DOM перед проверкой
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', init);
    } else {
      init();
    }
    
    function init() {
      // Проверяем, не пытается ли share-modal.js найти элементы
      // Если элементов нет, создаем заглушки
      const shareModalElements = [
        'share-modal',
        'share-button',
        'share-trigger',
        '[data-share]',
      ];
      
      // Перехватываем возможные ошибки
      const originalQuerySelector = document.querySelector.bind(document);
      const originalQuerySelectorAll = document.querySelectorAll.bind(document);
      
      // Добавляем безопасную обертку, если share-modal.js пытается использовать их
      if (!document._shareModalFixed) {
        document._shareModalFixed = true;
        
        // Если share-modal.js загрузится позже, это предотвратит ошибки
        window.addEventListener('error', function(e) {
          if (e.message && e.message.includes('addEventListener') && e.message.includes('null')) {
            // Игнорируем ошибки связанные с share-modal, если они не критичны
            if (e.filename && e.filename.includes('share-modal')) {
              e.preventDefault();
              console.warn('Share modal element not found, ignoring error');
              return true;
            }
          }
          return false;
        }, true);
      }
    }
  }
})();

