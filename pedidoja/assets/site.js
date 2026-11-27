// Pedido Já · menu, link ativo e simulador (sem dependências)
(function () {
  var botao = document.querySelector('.abre-menu');
  var gaveta = document.getElementById('gaveta');
  if (botao && gaveta) {
    botao.addEventListener('click', function () {
      var aberto = gaveta.classList.toggle('aberta');
      botao.setAttribute('aria-expanded', aberto ? 'true' : 'false');
      botao.setAttribute('aria-label', aberto ? 'Fechar menu' : 'Abrir menu');
    });
  }

  // fecha o submenu de funcionalidades ao clicar fora
  var sub = document.querySelector('.menu details');
  document.addEventListener('click', function (e) {
    if (sub && sub.open && !sub.contains(e.target)) sub.open = false;
  });

  // marca o link da página atual
  var aqui = location.href.split('#')[0].replace(/index\.html$/, '');
  document.querySelectorAll('.menu a, .gaveta a, .sub a').forEach(function (a) {
    if (a.href.replace(/index\.html$/, '') === aqui) a.setAttribute('aria-current', 'page');
  });

  // simulador de economia (página de planos)
  var faixa = document.getElementById('faturamento');
  if (faixa) {
    var reais = function (v) { return 'R$ ' + Math.round(v).toLocaleString('pt-BR'); };
    var atualiza = function () {
      var f = +faixa.value, comissao = f * 0.12, mensal = 300;
      document.getElementById('fat-valor').textContent = reais(f) + (f >= 60000 ? '+' : '');
      document.getElementById('sim-comissao').textContent = reais(comissao);
      document.getElementById('sim-plano').textContent = reais(mensal);
      document.getElementById('sim-sobra').textContent = reais(Math.max(comissao - mensal, 0));
    };
    faixa.addEventListener('input', atualiza);
    atualiza();
  }
})();
