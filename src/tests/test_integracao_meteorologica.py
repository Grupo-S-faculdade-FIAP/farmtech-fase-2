import unittest
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'esp32'))

from integracao_meteorologica_independente import obter_dados_meteorologicos, processar_previsao

class TestIntegracaoMeteorologica(unittest.TestCase):
    def setUp(self):
        """Configuração inicial para os testes"""
        self.latitude = -23.5505
        self.longitude = -46.6333
        
    def test_formato_dados_meteorologicos(self):
        """Testa se os dados meteorológicos têm o formato correto"""
        try:
            dados = obter_dados_meteorologicos(self.latitude, self.longitude)
            self.assertIsInstance(dados, dict)
            campos_necessarios = ['temperatura', 'umidade', 'chance_chuva']
            for campo in campos_necessarios:
                self.assertIn(campo, dados)
                self.assertIsNotNone(dados[campo])
            print("✓ OK: Formato dos dados meteorológicos válido")
        except Exception as e:
            print(f"❌ FALHA: Erro ao obter dados meteorológicos - {str(e)}")
            
    def test_validacao_parametros(self):
        """Testa a validação de parâmetros de latitude e longitude"""
        try:
            with self.assertRaises(ValueError):
                obter_dados_meteorologicos(91, 0)  # Latitude inválida
            with self.assertRaises(ValueError):
                obter_dados_meteorologicos(0, 181)  # Longitude inválida
            print("✓ OK: Validação de parâmetros funcionando")
        except Exception as e:
            print(f"❌ FALHA: Erro na validação de parâmetros - {str(e)}")
            
    def test_processamento_previsao(self):
        """Testa o processamento da previsão do tempo"""
        try:
            dados = {
                'temperatura': 25,
                'umidade': 60,
                'chance_chuva': 80
            }
            decisao = processar_previsao(dados)
            self.assertIsInstance(decisao, bool)
            print("✓ OK: Processamento da previsão funcionando")
        except Exception as e:
            print(f"❌ FALHA: Erro no processamento da previsão - {str(e)}")

if __name__ == '__main__':
    print("Iniciando testes unitários para integração meteorológica...")
    print("====================================================\n")
    unittest.main(argv=['first-arg-is-ignored'], exit=False)