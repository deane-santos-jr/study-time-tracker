import { Subject } from '../entities/Subject';

export interface ISubjectRepository {
  create(subject: Subject): Promise<Subject>;
  findById(id: string): Promise<Subject | null>;
  findByUserId(userId: string): Promise<Subject[]>;
  update(subject: Subject): Promise<Subject>;
  delete(id: string): Promise<void>;
}
