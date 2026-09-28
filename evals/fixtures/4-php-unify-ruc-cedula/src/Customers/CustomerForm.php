<?php
declare(strict_types=1);

namespace Acme\Crm\Customers;

use Acme\Crm\Validation\RucValidator;

final class CustomerForm
{
    /** @return array<string, string> errores por campo */
    public function validate(array $data): array
    {
        $errors = [];
        if (trim($data['nombre'] ?? '') === '') {
            $errors['nombre'] = 'El nombre es obligatorio';
        }
        $tipo = $data['tipo_identificacion'] ?? 'ruc';
        $id = $data['identificacion'] ?? '';
        if ($tipo === 'ruc' && !RucValidator::validarRuc($id)) {
            $errors['identificacion'] = 'RUC inválido';
        }
        // TODO: tipo 'cedula'
        return $errors;
    }
}
