require "rails_helper"

RSpec.describe Usuario, type: :model do
  it "es válido con los datos de la factory" do
    expect(build(:usuario)).to be_valid
  end

  it "exige nombre, email y rol" do
    usuario = Usuario.new(password: "secreto123")

    expect(usuario).not_to be_valid
    expect(usuario.errors.attribute_names).to include(:nombre, :email, :rol)
  end

  it "rechaza un rol desconocido" do
    expect(build(:usuario, rol: "gerente")).not_to be_valid
  end

  it "exige una contraseña de al menos 8 caracteres" do
    expect(build(:usuario, password: "corta")).not_to be_valid
  end

  it "normaliza el email" do
    expect(create(:usuario, email: "  Juan@Taller.TEST ").email).to eq("juan@taller.test")
  end

  it "no permite dos usuarios con el mismo email" do
    create(:usuario, email: "juan@taller.test")

    duplicado = build(:usuario, email: "JUAN@taller.test")

    expect(duplicado).not_to be_valid
    expect(duplicado.errors[:email]).to be_present
  end

  it "impide emails duplicados a nivel de base de datos" do
    create(:usuario, email: "juan@taller.test")
    duplicado = build(:usuario, email: "juan@taller.test")

    expect { duplicado.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
