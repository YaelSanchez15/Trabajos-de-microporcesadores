#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include "pico/stdlib.h"
#include "hardware/i2c.h"
#include "ssd1306_font.h"

// Configuración del tamaño de la pantalla SSD1306
#define SSD1306_HEIGHT              64
#define SSD1306_WIDTH               128

// Dirección I2C para el SSD1306
#define SSD1306_I2C_ADDR            _u(0x3C) // Dirección I2C del display
#define SSD1306_I2C_CLK             400  // Frecuencia de I2C en kHz

// Comandos para SSD1306
#define SSD1306_SET_MEM_MODE                _u(0x20)  // Configuracion del modo de direccionamiento horizontal
#define SSD1306_SET_COL_ADDR                _u(0x21)  // Configuracion del rango de direcciones de columnas
#define SSD1306_SET_PAGE_ADDR               _u(0x22)  // Configuracion el rango de direcciones de páginas
#define SSD1306_SET_DISP                    _u(0xAE)  // Encender/apagar display
#define SSD1306_SET_CHARGE_PUMP             _u(0x8D)  // Configuracion del generador de carga
#define SSD1306_SET_DISP_CLK_DIV            _u(0xD5)  // Configuracion del divisor de reloj
#define SSD1306_SET_VCOM_DESEL              _u(0xDB)  // Configuracion del nivel de deseleccion de VCOM
#define SSD1306_SET_NORM_DISP               _u(0xA6)  // Configuracion para tener el display en modo normal
#define SSD1306_SET_DISP_START_LINE         _u(0x40)  // Configuracion de la línea de inicio del display
#define SSD1306_SET_SEG_REMAP               _u(0xA0)  // Remapea los segmentos de la pantalla
#define SSD1306_SET_COM_OUT_DIR             _u(0xC0)  // Configuracion de la direccion de salida COM

#define SSD1306_BUF_LEN             (SSD1306_WIDTH * SSD1306_HEIGHT / 8)

// Estructura para definir el área de renderizado
struct render_area {
    uint8_t start_col;  // Columna de inicio
    uint8_t end_col;    // Columna de fin
    uint8_t start_page; // Página de inicio
    uint8_t end_page;   // Página de fin
    int buflen;         // Tamaño del búfer necesario
};

// Calcula el tamaño del búfer necesario para renderizar un área específica
void calc_render_area_buflen(struct render_area *area) {
    area->buflen = (area->end_col - area->start_col + 1) * (area->end_page - area->start_page + 1);
}

// Envía un comando al SSD1306
void SSD1306_send_cmd(uint8_t cmd) {
    uint8_t buf[2] = {0x80, cmd};  // 0x80 indica que es un comando
    i2c_write_blocking(i2c_default, SSD1306_I2C_ADDR, buf, 2, false);
}

// Envía un búfer de datos al SSD1306
void SSD1306_send_buf(uint8_t *buf, int buflen) {
    uint8_t *temp_buf = malloc(buflen + 1);
    temp_buf[0] = 0x40;  // 0x40 indica que es datos gráficos
    memcpy(temp_buf + 1, buf, buflen);
    i2c_write_blocking(i2c_default, SSD1306_I2C_ADDR, temp_buf, buflen + 1, false);
    free(temp_buf);
}

// Inicialización del SSD1306
void SSD1306_init() {
    uint8_t cmds[] = {
        SSD1306_SET_DISP | 0x00,        // Apagar display
        SSD1306_SET_MEM_MODE, 0x00,     // Modo de direccionamiento horizontal
        SSD1306_SET_DISP_START_LINE,    // Configura la línea de inicio del display
        SSD1306_SET_SEG_REMAP | 0X01,   // Remapear los segmentos (horizontalmente) para evitar que el mensaje salga al reves
        SSD1306_SET_COM_OUT_DIR | 0X08, // Configurar la dirección de salida de COM
        SSD1306_SET_CHARGE_PUMP, 0x14,  // Activar el generador de voltaje
        SSD1306_SET_DISP_CLK_DIV, 0x80, // Configuración de frecuencia
        SSD1306_SET_VCOM_DESEL, 0x30,   // Nivel de deselección de VCOMH
        SSD1306_SET_NORM_DISP,          // Modo normal de display (no invertido)
        SSD1306_SET_DISP | 0x01         // Encender display
    };
    for (int i = 0; i < sizeof(cmds); i++) {
        SSD1306_send_cmd(cmds[i]);
    }
}

// Renderiza el contenido de un área específica de la pantalla
void render(uint8_t *buf, struct render_area *area) {
    uint8_t cmds[] = {
        SSD1306_SET_COL_ADDR, area->start_col, area->end_col,
        SSD1306_SET_PAGE_ADDR, area->start_page, area->end_page
    };
    for (int i = 0; i < sizeof(cmds); i++) {
        SSD1306_send_cmd(cmds[i]);
    }
    SSD1306_send_buf(buf, area->buflen);
}

// Obtiene un carácter del font
int GetFontIndex(uint8_t ch) {
    if (ch >= 'A' && ch <= 'Z') {
        return ch - 'A' + 1;
    } else {
        return 0;  // Espacio 
    }
}

// Escribe un carácter en la pantalla
void WriteChar(uint8_t *buf, int16_t x, int16_t y, uint8_t ch) {
    if (x > SSD1306_WIDTH - 8 || y > SSD1306_HEIGHT - 8) return;
    y /= 8;  // Posicionar en filas de 8 píxeles
    int idx = GetFontIndex(toupper(ch));
    int fb_idx = y * SSD1306_WIDTH + x;
    for (int i = 0; i < 8; i++) {
        buf[fb_idx++] = font[idx * 8 + i];
    }
}

// Escribe una cadena en la pantalla
void WriteString(uint8_t *buf, int16_t x, int16_t y, char *str) {
    while (*str && x <= SSD1306_WIDTH - 8) {
        WriteChar(buf, x, y, *str++);
        x += 8;   // Avanzar 8 píxeles para el siguiente carácter
    }
}

int main() {
    stdio_init_all();

#if !defined(i2c_default)
#warning i2c / SSD1306_i2c example requires a board with I2C pins
    puts("I2C pins not defined");
#else
    i2c_init(i2c_default, SSD1306_I2C_CLK * 1000);
    // Configuracion de los pines para SDA y SCL
    gpio_set_function(PICO_DEFAULT_I2C_SDA_PIN, GPIO_FUNC_I2C);
    gpio_set_function(PICO_DEFAULT_I2C_SCL_PIN, GPIO_FUNC_I2C);

    //Habilita la resistencia Pull Up de los pines SDA y SCL
    gpio_pull_up(PICO_DEFAULT_I2C_SDA_PIN);
    gpio_pull_up(PICO_DEFAULT_I2C_SCL_PIN);

    SSD1306_init();

    struct render_area frame_area = {0, SSD1306_WIDTH - 1, 0, (SSD1306_HEIGHT / 8) - 1};
    calc_render_area_buflen(&frame_area);

    uint8_t buf[SSD1306_BUF_LEN];
    memset(buf, 0, SSD1306_BUF_LEN);  // Limpia la pantalla

    // Escribe mi nombre en la pantalla
    WriteString(buf, 37, 0, "Yael Isai");
    WriteString(buf, 43, 8, "Sanchez");
    WriteString(buf, 49, 16, "Rojas");

    render(buf, &frame_area);

    // Bucle para mantener el texto en pantalla
    while (1) {
        sleep_ms(1000);
    }

#endif
    return 0;
}
