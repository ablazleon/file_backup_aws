# Se crea una conexión con el agente
resource "aws_datasync_agent" "datasync_agent_tf" {
  ip_address = aws_instance.ds-agent_tf.public_ip
  name       = "datasync_agent"
  # Depende que se cree la conexión con el agente de que se haya creado la vm agente
  depends_on = [aws_instance.ds-agent_tf]
}